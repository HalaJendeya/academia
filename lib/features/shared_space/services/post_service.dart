// lib/features/shared_space/services/post_service.dart

import '../models/comment_model.dart';
import '../models/post_attachment.dart';
import '../models/post_model.dart';

class PostException implements Exception {
  final String message;
  const PostException(this.message);

  @override
  String toString() => message;
}

/// بيانات ساحة المشاركة (منشورات وتعليقات).
///
/// Mock بالكامل حاليًا (بلا Firebase) — نفس نمط StudentFileService بمرحلته
/// الأولى: التوقيع غير المتزامن (Future) محفوظ كما سيكون مع Firestore
/// لاحقًا، فاستبدال هذه الخدمة بخدمة حقيقية لن يغيّر شيئًا في
/// [PostProvider] ولا أي شاشة تستهلكها. الاستعلام الحقيقي المتوقَّع لاحقًا:
/// `courseFiles`-مثل مجموعة `posts` بحقل courseId، ومجموعة فرعية أو
/// مجموعة `comments` بحقل postId.
class PostService {
  PostService();

  static const Duration _mockDelay = Duration(milliseconds: 400);

  /// نسخ قابلة للتعديل من القوائم الوهمية، لأن الإعجاب والنشر والتعليق
  /// بمرحلة الـ Mock تعدّل الحالة محليًا (لا مصدر حقيقي يُعاد الاستعلام منه).
  final List<PostModel> _posts = List.of(_mockPosts);
  final List<CommentModel> _comments = List.of(_mockComments);

  Future<List<PostModel>> getPostsForCourse(String courseId) async {
    await Future.delayed(_mockDelay);
    return _posts.where((p) => p.courseId == courseId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<PostModel> toggleLike(String postId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) {
      throw const PostException('لم يتم العثور على المنشور.');
    }
    final post = _posts[index];
    final updated = post.copyWith(
      isLikedByMe: !post.isLikedByMe,
      likesCount: post.isLikedByMe
          ? post.likesCount - 1
          : post.likesCount + 1,
    );
    _posts[index] = updated;
    return updated;
  }

  Future<PostModel> createPost({
    required String courseId,
    required String content,
    PostAttachment? attachment,
  }) async {
    await Future.delayed(_mockDelay);
    final post = PostModel(
      id: 'post_${DateTime.now().microsecondsSinceEpoch}',
      courseId: courseId,
      authorName: 'أنا',
      authorRole: 'طالب',
      content: content,
      attachment: attachment,
      createdAt: DateTime.now(),
    );
    _posts.insert(0, post);
    return post;
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
    String notes = '',
  }) async {
    await Future.delayed(_mockDelay);
    // لا تأثير حقيقي بمرحلة الـ Mock — الإبلاغ لا يُخزَّن ولا يُرسَل بعد.
  }

  // ---------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------

  Future<List<CommentModel>> getCommentsForPost(String postId) async {
    await Future.delayed(_mockDelay);
    return _comments.where((c) => c.postId == postId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<CommentModel> addComment({
    required String postId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final comment = CommentModel(
      id: 'comment_${DateTime.now().microsecondsSinceEpoch}',
      postId: postId,
      authorName: 'أنا',
      content: content,
      createdAt: DateTime.now(),
    );
    _comments.add(comment);

    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      _posts[postIndex] = _posts[postIndex].copyWith(
        commentsCount: _posts[postIndex].commentsCount + 1,
      );
    }

    return comment;
  }

  // ---------------------------------------------------------------------
  // Mock Data
  // ---------------------------------------------------------------------

  static final List<PostModel> _mockPosts = [
    PostModel(
      id: 'post_1',
      courseId: 'sOY9FFM4LTdvHMuzcI9c',
      authorName: 'محمد سعيد',
      authorRole: 'ط. ساعتين - هندسة البرمجيات',
      content:
      'هل ممكن أحد شرح لي طرح الفرق الأساسي بين RIST و REST أو إذا حد '
          'واجه صعوبة في فهم ربط استخدام GraphQL و APIs أيضًا في مشروعي '
          'القادم؟',
      attachment: null,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likesCount: 12,
      commentsCount: 5,
    ),
    PostModel(
      id: 'post_2',
      courseId: 'sOY9FFM4LTdvHMuzcI9c',
      authorName: 'ليلى عبدالله',
      authorRole: 'مشرف - مساعد المستوى',
      content:
      'تذكير: موعد تسليم المشروع النهائي المتعلق بتصميم الواجهات الثالث '
          'هو يوم الأحد القادم. الرجاء التأكد من مراجعة معايير التقييم '
          'الموجودة في المنصة.',
      attachment: null,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      likesCount: 34,
      commentsCount: 2,
    ),
    PostModel(
      id: 'post_3',
      courseId: 'sOY9FFM4LTdvHMuzcI9c',
      authorName: 'أحمد محمد',
      authorRole: 'طالب - تراكيب البيانات',
      content:
      'هل أحد لديه ملخص لمادة تراكيب البيانات؟ أحتاج لمراجعة خوارزميات '
          'البحث الثاني قبل الاختبار القادم.',
      attachment: const PostAttachment(
        fileName: 'Summary_DS.pdf',
        sizeLabel: '1.2 MB',
        fileExtension: 'pdf',
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      likesCount: 12,
      commentsCount: 2,
    ),
  ];

  static final List<CommentModel> _mockComments = [
    CommentModel(
      id: 'comment_1',
      postId: 'post_3',
      authorName: 'سارة خالد',
      content: 'لدي ملخص شامل قمت بإعداده الأسبوع الماضي، سأقوم برفعه لك هنا حالًا.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    CommentModel(
      id: 'comment_2',
      postId: 'post_3',
      authorName: 'عمر فاروق',
      content:
      'أنصحك أيضًا بمشاهدة شرح قناة "الخوارزميات بالعربي" على يوتيوب، ساعدني '
          'كثيرًا في فهم البحث الثاني.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];
}

