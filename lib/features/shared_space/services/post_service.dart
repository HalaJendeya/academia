// lib/features/shared_space/services/post_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../notifications/services/notification_service.dart';
import '../models/comment_model.dart';
import '../models/post_attachment.dart';
import '../models/post_model.dart';
import '../models/post_report_model.dart';

class PostException implements Exception {
  final String message;
  const PostException(this.message);

  @override
  String toString() => message;
}

/// دفعة واحدة من "تحميل المزيد" — منشورات الصفحة مع مؤشر بسيط لوجود
/// المزيد من عدمه. ليست Stream عمدًا: صفحات لاحقة لا تتحدّث لحظيًا،
/// انظر توثيق [PostService.watchPostsForCourse].
class PostsPage {
  const PostsPage({required this.posts, required this.hasMore});

  final List<PostModel> posts;
  final bool hasMore;
}

/// بيانات ساحة المشاركة — Firestore حقيقي بالكامل.
///
/// اللايكات لا تُخزَّن كرقم فقط: كل إعجاب مستند مستقل في
/// posts/{postId}/likes/{userId}. هذا هو إصلاح خلل "-2" الذي كان يصيب
/// likesCount عندما لا يُتحقَّق من حالة المستخدم قبل الزيادة/النقصان —
/// الآن كل مستخدم له مستند إعجاب واحد بالضبط، ومستحيل تكراره أو نقصانه
/// دون وجوده أصلًا.
class PostService {
  PostService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    NotificationService? notificationService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final NotificationService _notificationService;

  CollectionReference<Map<String, dynamic>> get _posts => _db.collection('posts');
  CollectionReference<Map<String, dynamic>> get _postReports =>
      _db.collection('postReports');

  String get _requireUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const PostException('يجب تسجيل الدخول أولًا.');
    }
    return uid;
  }

  /// اسم صاحب الحساب المعروض، من المصدر الوحيد المعتمد: `users/{uid}`.
  ///
  /// 🔴 لا يُقرأ الاسم من مزوّد خاص بالطالب.
  ///
  /// كان الاسم يأتي من ProfileProvider، وهو مزوّد ملف الطالب وحده. فإن لم
  /// يكن قد حُمِّل بعد — أو كان صاحب الحساب معلّمًا أو مشرفًا لا ملف طالب
  /// له — يعود null، فتقول الشاشة «أعيدي تسجيل الدخول» لمستخدم جلسته
  /// سليمة تمامًا. الهوية هنا هي هوية المصادقة، والاسم صفة تُقرأ من مستند
  /// المستخدم العام الذي تملكه الأدوار الثلاثة جميعًا.
  ///
  /// وتُميَّز الحالتان: غياب المصادقة شيء، وغياب مستند المستخدم شيء آخر —
  /// ولكلٍّ رسالته الصادقة.
  Future<String> _requireAuthorName() async {
    final uid = _requireUserId;

    // ذاكرة داخل الجلسة: الاسم لا يتغيّر بين تعليق وآخر، فلا داعي لقراءة
    // مستند المستخدم مع كل كتابة.
    final cached = _cachedAuthorName;
    if (cached != null && _cachedAuthorUid == uid) return cached;

    final Map<String, dynamic>? data;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      data = doc.data();
    } catch (e) {
      throw const PostException('تعذر قراءة بيانات حسابك، حاول مرة أخرى.');
    }

    if (data == null) {
      throw const PostException(
        'لم يتم العثور على بيانات حسابك. تواصل مع إدارة النظام.',
      );
    }

    final name = (data['fullName'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      throw const PostException(
        'اسم حسابك غير مسجَّل. تواصل مع إدارة النظام.',
      );
    }

    _cachedAuthorUid = uid;
    _cachedAuthorName = name;
    return name;
  }

  String? _cachedAuthorUid;
  String? _cachedAuthorName;

  /// يتحقق أن المستخدم الحالي أدمن، عبر حقل role بمستنده في users — نفس
  /// الشرط المعتمَد بكل شاشات الإدارة الأخرى بالمشروع (لا معيار جديد هنا).
  Future<void> _requireAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const PostException('يجب تسجيل الدخول أولًا.');
    }
    final userDoc = await _db.collection('users').doc(uid).get();
    final role = userDoc.data()?['role'] as String?;
    if (role != 'admin') {
      throw const PostException('هذه الشاشة متاحة للمشرفين فقط.');
    }
  }

  // ---------------------------------------------------------------------
  // Posts
  // ---------------------------------------------------------------------

  /// حجم الصفحة الافتراضي: أول شريحة (حيّة، Stream) وكل "تحميل المزيد"
  /// بنفس الحجم — رقم واحد متّفق عليه بدل قيم متفرقة بكل مكان.
  static const int pageSize = 20;

  /// منشورات مساق واحد، الأحدث أولًا، محدودة بأول [limit] منشور فقط —
  /// نفس مبدأ أي تغذية (Feed) لا تُحمَّل كاملة: الصفحة الأولى وحدها حيّة
  /// (Stream)؛ ما بعدها عبر [getOlderPosts] كطلب لمرة واحدة، فلا تتحدّث
  /// لحظيًا — تبسيط مقصود يتجنّب تعقيد دمج صفحات حيّة متعددة معًا.
  ///
  /// لا تحمل [PostModel.isLikedByMe] — ذاك يُحدَّد لكل منشور على حدة عبر
  /// [isPostLikedByMe]، لأن التحقق داخل استعلام قائمة كامل لكل تحديث لحظي
  /// مكلف بلا داعٍ.
  Stream<List<PostModel>> watchPostsForCourse(
      String courseId, {
        int limit = pageSize,
      }) {
    return _posts
        .where('courseId', isEqualTo: courseId)
        .where('status', isEqualTo: PostModel.statusActive)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc.data(), doc.id))
        .toList())
        .handleError((_) {
      throw const PostException('تعذر تحميل منشورات المساحة، حاول مرة أخرى.');
    });
  }

  /// الدفعة التالية من المنشورات الأقدم من [before] — طلب لمرة واحدة، لا
  /// Stream. [hasMore] بالنتيجة تعكس امتلاء الدفعة (== limit)، لا عدّادًا
  /// حقيقيًا لما تبقّى؛ مؤشّر كافٍ لإخفاء/إظهار زر "تحميل المزيد".
  Future<PostsPage> getOlderPosts({
    required String courseId,
    required DateTime before,
    int limit = pageSize,
  }) async {
    try {
      final snapshot = await _posts
          .where('courseId', isEqualTo: courseId)
          .where('status', isEqualTo: PostModel.statusActive)
          .orderBy('createdAt', descending: true)
          .startAfter([Timestamp.fromDate(before)])
          .limit(limit)
          .get();

      final posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc.data(), doc.id))
          .toList();

      return PostsPage(posts: posts, hasMore: posts.length == limit);
    } catch (e) {
      throw const PostException('تعذر تحميل المزيد من المنشورات، حاول مرة أخرى.');
    }
  }

  Future<bool> isPostLikedByMe(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;
    try {
      final doc = await _posts.doc(postId).collection('likes').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> createPost({
    required String courseId,
    String authorRole = '',
    required String content,
    PostAttachment? attachment,
  }) async {
    late final String postId;
    // يُقرأ قبل الكتابة: فشل قراءة الاسم يجب ألا يترك منشورًا بلا صاحب.
    final authorName = await _requireAuthorName();
    try {
      final model = PostModel(
        id: '',
        courseId: courseId,
        authorId: _requireUserId,
        authorName: authorName,
        authorRole: authorRole,
        content: content,
        attachment: attachment,
        createdAt: DateTime.now(),
      );
      final docRef = await _posts.add(model.toFirestore());
      postId = docRef.id;
    } on PostException {
      rethrow;
    } catch (e) {
      throw const PostException('تعذر نشر المنشور، حاول مرة أخرى.');
    }

    // إشعار الزملاء بعد نجاح النشر فعليًا، لا قبله — منشور محفوظ بلا
    // إشعار أهون بكثير من إشعار عن منشور لم يُحفظ. فشل هذه الخطوة لا يجعل
    // النشر نفسه يبدو فاشلًا للطالب.
    try {
      await _notificationService.notifyCourseClassmatesOfNewPost(
        courseId: courseId,
        postId: postId,
        authorName: authorName,
      );
    } catch (e) {
      // يُبتلَع عمدًا: إشعار ثانوي، لا يستحق إفشال تجربة نشر منشور ناجح.
    }
  }

  /// تعديل محتوى منشور موجود (النص والمرفق). لا تُعدَّل بقية الحقول
  /// (authorId, courseId, createdAt, likesCount, commentsCount, status) —
  /// نفس ما تفرضه قاعدة posts.update بـ Firestore، فهذا التحقق المحلي
  /// انعكاس للقاعدة الحقيقية لا بديل عنها؛ Firestore يرفض أي محاولة
  /// تجاوزها بغض النظر عمّا يرسله العميل.
  Future<void> updatePost({
    required String postId,
    required String content,
    PostAttachment? attachment,
  }) async {
    try {
      await _posts.doc(postId).update({
        'content': content,
        'attachment': attachment?.toMap(),
      });
    } catch (e) {
      throw const PostException('تعذر حفظ التعديلات، حاول مرة أخرى.');
    }
  }

  /// حذف منطقي فقط (status = archived)، لا حذف فعلي — نفس مبدأ
  /// CourseFileService.archiveFile.
  Future<void> archivePost(String postId) async {
    try {
      await _posts.doc(postId).update({'status': PostModel.statusArchived});
    } catch (e) {
      throw const PostException('تعذر حذف المنشور، حاول مرة أخرى.');
    }
  }

  /// يبدّل حالة الإعجاب بمعاملة (Transaction) ذرّية: قراءة حالة الإعجاب
  /// وعدّاد المنشور معًا، ثم كتابة الاثنين معًا. هذا يمنع بنيويًا أي عدّاد
  /// سالب أو تكرار إعجاب لنفس المستخدم، بخلاف زيادة/نقصان مباشرة بلا تحقق.
  ///
  /// يُعيد الحالة الجديدة (true = صار معجبًا به الآن).
  Future<bool> toggleLike(String postId) async {
    final userId = _requireUserId;
    final postRef = _posts.doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    try {
      return await _db.runTransaction<bool>((transaction) async {
        final likeSnap = await transaction.get(likeRef);
        final postSnap = await transaction.get(postRef);

        if (!postSnap.exists) {
          throw const PostException('لم يتم العثور على المنشور.');
        }

        final currentCount =
            (postSnap.data()?['likesCount'] as num?)?.toInt() ?? 0;

        if (likeSnap.exists) {
          transaction.delete(likeRef);
          transaction.update(postRef, {
            'likesCount': currentCount > 0 ? currentCount - 1 : 0,
          });
          return false;
        } else {
          transaction.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
          transaction.update(postRef, {'likesCount': currentCount + 1});
          return true;
        }
      });
    } on PostException {
      rethrow;
    } catch (e) {
      throw const PostException('تعذر تسجيل الإعجاب، حاول مرة أخرى.');
    }
  }

  Future<void> reportPost({
    required String postId,
    required String courseId,
    required String reason,
    String notes = '',
  }) async {
    final reporterName = await _requireAuthorName();
    try {
      await _postReports.add({
        'postId': postId,
        'courseId': courseId,
        'reporterId': _requireUserId,
        'reporterName': reporterName,
        'reason': reason,
        'notes': notes,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on PostException {
      rethrow;
    } catch (e) {
      throw const PostException('تعذر إرسال البلاغ، حاول مرة أخرى.');
    }
  }

  // ---------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------

  Stream<List<CommentModel>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CommentModel.fromFirestore(doc.data(), doc.id, postId))
        .toList())
        .handleError((_) {
      throw const PostException('تعذر تحميل التعليقات، حاول مرة أخرى.');
    });
  }

  /// إضافة تعليق وزيادة commentsCount بنفس العملية (Batch)، بدل كتابتين
  /// منفصلتين قد تنجح إحداهما وتفشل الأخرى.
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final userId = _requireUserId;
      // الاسم من users/{uid}، لا من مزوّد الواجهة.
      final authorName = await _requireAuthorName();
      final postRef = _posts.doc(postId);
      final commentRef = postRef.collection('comments').doc();

      final comment = CommentModel(
        id: commentRef.id,
        postId: postId,
        authorId: userId,
        authorName: authorName,
        content: content,
        createdAt: DateTime.now(),
      );

      final batch = _db.batch();
      batch.set(commentRef, comment.toFirestore());
      batch.update(postRef, {'commentsCount': FieldValue.increment(1)});
      await batch.commit();
    } on PostException {
      rethrow;
    } catch (e) {
      throw const PostException('تعذر إرسال الرد، حاول مرة أخرى.');
    }
  }

  // ---------------------------------------------------------------------
  // Admin: Reported Posts Queue
  // ---------------------------------------------------------------------

  /// البلاغات المعلَّقة فقط (status = pending)، الأحدث أولًا. المراجَعة
  /// تختفي من القائمة فور حسمها، لا حاجة لفلترة يدوية بالواجهة.
  Stream<List<PostReportModel>> watchPendingReports() {
    return _postReports
        .where('status', isEqualTo: PostReportModel.statusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PostReportModel.fromFirestore(doc.data(), doc.id))
        .toList())
        .handleError((_) {
      throw const PostException('تعذر تحميل البلاغات، حاول مرة أخرى.');
    });
  }

  /// ملخّص المنشور المُبلَّغ عنه، لعرضه بجانب البلاغ — بلاغ بلا سياق المنشور
  /// نفسه عديم الفائدة للمراجعة. يعيد null إن كان المنشور محذوفًا مسبقًا.
  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await _posts.doc(postId).get();
      if (!doc.exists) return null;
      return PostModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  /// حسم البلاغ بلا إجراء على المنشور (البلاغ غير مبرَّر).
  Future<void> dismissReport(String reportId) async {
    await _requireAdmin();
    try {
      await _postReports
          .doc(reportId)
          .update({'status': PostReportModel.statusResolved});
    } catch (e) {
      throw const PostException('تعذر تحديث حالة البلاغ، حاول مرة أخرى.');
    }
  }

  /// أرشفة المنشور المخالف وحسم البلاغ معًا بعملية واحدة (Batch) — إجراء
  /// واحد يعكس نيّة واحدة (البلاغ مبرَّر)، لا كتابتين قد تنجح إحداهما فقط.
  Future<void> archiveReportedPost({
    required String postId,
    required String reportId,
  }) async {
    await _requireAdmin();
    try {
      final batch = _db.batch();
      batch.update(_posts.doc(postId), {'status': PostModel.statusArchived});
      batch.update(_postReports.doc(reportId), {
        'status': PostReportModel.statusResolved,
      });
      await batch.commit();
    } catch (e) {
      throw const PostException('تعذر تنفيذ الإجراء، حاول مرة أخرى.');
    }
  }
}