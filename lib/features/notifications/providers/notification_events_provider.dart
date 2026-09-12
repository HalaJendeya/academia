// lib/features/notifications/providers/notification_events_provider.dart

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../assignments/models/course_assignment_model.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../../shared_space/models/post_model.dart';
import '../models/app_notification.dart';
import '../services/notification_event_ports.dart';

/*
 * كشف الأحداث الأكاديمية وتحويلها إلى إشعارات داخل التطبيق — على خطة
 * Spark المجانية، بلا خادم وبلا Cloud Functions.
 *
 * ═══════════════ لماذا هذا الاتجاه بالذات ═══════════════
 *
 * المعمارية القديمة كانت معكوسة: الناشر يبحث عن زملائه ثم يكتب لهم
 * إشعارات. وهي مستحيلة أمنيًا — الطالب لا يقرأ مستندات زملائه ولا صفوف
 * تسجيلهم، ولا يجوز أن يفعل.
 *
 * 🔴 هنا العكس تمامًا: **المستلم يكتشف ما يخصّه**.
 *
 * تطبيق الطالبة يستمع إلى بيانات هي مخوَّلة بقراءتها أصلًا (منشورات
 * مساقاتها، واجبات شُعبها)، فإن ظهر حدث أحدث من حدّها كتبت لنفسها إشعارًا.
 * لا أحد يستعلم عن أحد، ولا صلاحية واحدة تُوسَّع.
 *
 * ═══════════════ ما تفعله وما لا تفعله ═══════════════
 *
 * ✅ حدث وقع والتطبيق **مغلق** يُكتشف عند فتحه التالي: الحدّ محفوظ على
 *    الجهاز، والاستماع يبدأ من عنده لا من لحظة الفتح.
 * ❌ لا يصل شيء إلى الجهاز وهو مغلق. هذا يحتاج مُرسِلًا على خادم، وهو
 *    خارج خطة Spark. بنية FCM من المرحلة الأولى باقية كما هي ولا يعتمد
 *    عليها هذا الكشف إطلاقًا.
 */
class NotificationEventsProvider extends ChangeNotifier {
  NotificationEventsProvider(this._feeds, this._checkpoints);

  final NotificationEventFeeds _feeds;
  final NotificationCheckpointStore _checkpoints;

  /// فئات الأحداث — لكل فئة حدّها المستقل.
  static const String postCategory = 'post';
  static const String assignmentCategory = 'assignment';
  static const List<String> categories = [postCategory, assignmentCategory];

  String? _currentUid;

  StreamSubscription<List<EnrollmentModel>>? _enrollmentsSub;
  final Map<String, StreamSubscription<List<PostModel>>> _postSubs = {};
  final Map<String, StreamSubscription<List<CourseAssignmentModel>>>
      _assignmentSubs = {};

  EventNotificationPreferences _preferences =
      const EventNotificationPreferences.none();

  /*
   * حدّ زمني **لكل فئة على حدة**.
   *
   * 🔴 حدّ واحد مشترك كان يُضيع أحداثًا.
   *
   * تدفّقا المنشورات والواجبات مستقلان ويصلان بترتيب غير مضمون. بحدّ
   * مشترك، معالجةُ منشورٍ في الثانية عشرة تدفع الحدّ إلى 12:00، فإذا وصل
   * بعدها واجبٌ أُنشئ في 11:30 عُدَّ "قديمًا" وضاع نهائيًا. فصل الحدّين
   * يجعل تقدّم أحد التدفّقين لا يكتم الآخر.
   */
  final Map<String, DateTime> _checkpoint = {};

  bool _isSyncing = false;

  @visibleForTesting
  DateTime? checkpointFor(String category) => _checkpoint[category];

  @visibleForTesting
  int get activeCourseListeners => _postSubs.length;

  @visibleForTesting
  int get activeOfferingListeners => _assignmentSubs.length;

  @visibleForTesting
  bool get hasEnrollmentListener => _enrollmentsSub != null;

  /*
   * تُستدعى من ChangeNotifierProxyProvider.update، أي أثناء البناء.
   * لذلك تبقى متزامنة ولا تنتظر ولا تُشعر المستمعين مباشرة — كل العمل
   * يُؤجَّل إلى microtask، بنفس نمط بقية المزوّدات المرتبطة بالمصادقة.
   */
  void syncWithAuth({String? uid}) {
    if (_currentUid == uid) return;
    _currentUid = uid;

    if (uid == null) {
      _teardown();
      return;
    }

    scheduleMicrotask(() => _start(uid));
  }

  Future<void> _start(String uid) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      // الحساب قد يكون تبدّل بين جدولة المهمة وتنفيذها.
      if (_currentUid != uid) return;

      _teardownSubscriptions();
      _checkpoint.clear();

      for (final category in categories) {
        final stored = await _checkpoints.read(uid, category);
        if (_currentUid != uid) return;

        if (stored != null) {
          /*
           * حدّ محفوظ: يُستأنف من عنده لا من الآن.
           *
           * 🔴 هذا ما يجعل حدثًا وقع والتطبيق مغلق قابلًا للاكتشاف. لو
           * استعملنا لحظة الدخول خط أساس جديدًا لضاع كل ما جرى بين
           * الجلستين.
           */
          _checkpoint[category] = stored;
        } else {
          // أول استعمال لهذا الحساب على هذا الجهاز: خط الأساس هو الآن،
          // فلا يتحول تاريخ الفصل كله إلى إشعارات.
          final baseline = DateTime.now();
          _checkpoint[category] = baseline;
          await _checkpoints.write(uid, category, baseline);
        }
      }

      try {
        _preferences = await _feeds.readMyPreferences();
      } catch (e) {
        // تعذّرت قراءة التفضيلات: لا إزعاج بدل الافتراض.
        _preferences = const EventNotificationPreferences.none();
      }
      if (_currentUid != uid) return;

      _enrollmentsSub = _feeds.watchMyEnrollments().listen(
        (enrollments) => _onEnrollments(uid, enrollments),
        onError: (Object _) {
          // فشل قراءة تسجيلاتي لا يُسقط التطبيق؛ لا إشعارات فقط.
        },
      );
    } finally {
      _isSyncing = false;
    }
  }

  void _onEnrollments(String uid, List<EnrollmentModel> enrollments) {
    if (_currentUid != uid) return;

    final courseIds = <String>{};
    final offeringIds = <String>{};
    for (final enrollment in enrollments) {
      if (!enrollment.isActive) continue;
      if (enrollment.courseId.isNotEmpty) courseIds.add(enrollment.courseId);
      if (enrollment.offeringId.isNotEmpty) {
        offeringIds.add(enrollment.offeringId);
      }
    }

    _reconcile<List<PostModel>>(
      subscriptions: _postSubs,
      wanted: courseIds,
      subscribe: (courseId) => _feeds.watchPostsForCourse(courseId).listen(
            (posts) => _onPosts(uid, courseId, posts),
            onError: (Object _) {},
          ),
    );

    _reconcile<List<CourseAssignmentModel>>(
      subscriptions: _assignmentSubs,
      wanted: offeringIds,
      subscribe: (offeringId) =>
          _feeds.watchOfferingAssignments(offeringId).listen(
                (assignments) => _onAssignments(uid, assignments),
                onError: (Object _) {},
              ),
    );
  }

  /// يضيف اشتراكًا لكل مفتاح جديد ويلغي اشتراك كل مفتاح لم يعد مطلوبًا.
  ///
  /// إلغاء الاشتراكات الزائدة ضروري: انسحاب الطالبة من مساق يجب أن يوقف
  /// إشعاراته، وإلا تراكمت الاشتراكات مع كل تحديث للتسجيلات.
  void _reconcile<T>({
    required Map<String, StreamSubscription<T>> subscriptions,
    required Set<String> wanted,
    required StreamSubscription<T> Function(String key) subscribe,
  }) {
    for (final key in subscriptions.keys.toList()) {
      if (wanted.contains(key)) continue;
      subscriptions.remove(key)?.cancel();
    }
    for (final key in wanted) {
      if (subscriptions.containsKey(key)) continue;
      subscriptions[key] = subscribe(key);
    }
  }

  Future<void> _onPosts(
    String uid,
    String courseId,
    List<PostModel> posts,
  ) async {
    if (_currentUid != uid || !_preferences.sharedSpace) return;

    final events = <_DetectedEvent>[];
    for (final post in posts) {
      if (post.authorId == uid) continue; // لا إشعار بمنشوري أنا
      if (!post.isActive) continue;
      events.add(
        _DetectedEvent(
          at: post.createdAt,
          notificationId: 'post_${post.id}_$uid',
          type: AppNotification.typeNewSharedSpacePost,
          title: 'منشور جديد في المساحة المشتركة',
          /*
           * نص عام لا يذكر اسم الناشر.
           *
           * اسم الناشر مخزَّن على المنشور نفسه وتعرضه الشاشة أصلًا، لكن
           * النص العام يبقى صحيحًا حتى لو غاب الحقل — ولا يُقرأ مستند
           * الناشر إطلاقًا لبناء هذا النص.
           */
          body: 'تم نشر منشور جديد في المساحة المشتركة',
          courseId: courseId,
          postId: post.id,
        ),
      );
    }

    await _processCategory(uid, postCategory, events);
  }

  Future<void> _onAssignments(
    String uid,
    List<CourseAssignmentModel> assignments,
  ) async {
    if (_currentUid != uid || !_preferences.assignments) return;

    final events = <_DetectedEvent>[];
    for (final assignment in assignments) {
      final createdAt = assignment.createdAt;
      if (createdAt == null) continue; // بلا زمن لا يمكن تمييز الجديد
      if (assignment.status != CourseAssignmentModel.statusActive) continue;
      events.add(
        _DetectedEvent(
          at: createdAt,
          notificationId: 'assignment_${assignment.id}_$uid',
          type: AppNotification.typeNewAssignment,
          title: 'واجب جديد',
          body: assignment.title,
          courseId: assignment.courseId,
          assignmentId: assignment.id,
        ),
      );
    }

    await _processCategory(uid, assignmentCategory, events);
  }

  /*
   * معالجة لقطة واحدة من فئة واحدة.
   *
   * 🔴 الترتيب هنا هو ما يمنع ضياع الأحداث.
   *
   * أولًا: تُقارن كل الأحداث بالحدّ **كما كان عند بداية اللقطة**، لا بحدٍّ
   * يتحرك أثناء الحلقة. استعلام المنشورات يعيدها بترتيب تنازلي، فمعالجةُ
   * الأحدث أولًا مع تحريك الحدّ فورًا كانت تقفز فوق منشورٍ أقدم في اللقطة
   * نفسها فيضيع — وهذا يحدث بالضبط حين يُنشَر أكثر من منشور والتطبيق مغلق.
   *
   * وثانيًا: تُعالَج تصاعديًا (الأقدم أولًا)، ولا يتقدّم الحدّ إلا خلف حدث
   * كُتب فعلًا. فإن فشلت كتابة أحدها توقّفت الحلقة عنده: يبقى الحدّ قبله،
   * فتُعاد المحاولة مع اللقطة التالية ولا يُفقد شيء.
   */
  Future<void> _processCategory(
    String uid,
    String category,
    List<_DetectedEvent> events,
  ) async {
    final boundary = _checkpoint[category];
    if (boundary == null) return;

    final fresh = events.where((event) => event.at.isAfter(boundary)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    if (fresh.isEmpty) return;

    DateTime? advancedTo;
    var emitted = false;

    for (final event in fresh) {
      if (_currentUid != uid) return; // الجلسة انتهت أثناء المعالجة
      final handled = await _handle(event);
      if (!handled) break; // فشل عابر: لا يتقدّم الحدّ فوقه
      advancedTo = event.at;
      emitted = true;
    }

    if (advancedTo == null) return;
    if (_currentUid != uid) return;

    final current = _checkpoint[category];
    if (current != null && !advancedTo.isAfter(current)) return;

    _checkpoint[category] = advancedTo;
    await _checkpoints.write(uid, category, advancedTo);

    if (emitted) notifyListeners();
  }

  /// يعيد true إن صار للحدث إشعار (أُنشئ الآن أو كان موجودًا مسبقًا).
  ///
  /// "موجود مسبقًا" نجاحٌ لا فشل: المعرّف حتمي، فوجوده يعني أن الحدث
  /// عولج سابقًا — ولا يجوز أن يوقف تقدّم الحدّ إلى الأبد.
  Future<bool> _handle(_DetectedEvent event) async {
    try {
      await _feeds.createSelfNotificationIfAbsent(
        notificationId: event.notificationId,
        type: event.type,
        title: event.title,
        body: event.body,
        courseId: event.courseId,
        postId: event.postId,
        assignmentId: event.assignmentId,
      );
      return true;
    } catch (e) {
      // عابر (شبكة مثلًا): يُترك الحدّ مكانه ليُعاد المحاولة لاحقًا.
      return false;
    }
  }

  void _teardownSubscriptions() {
    _enrollmentsSub?.cancel();
    _enrollmentsSub = null;
    for (final sub in _postSubs.values) {
      sub.cancel();
    }
    _postSubs.clear();
    for (final sub in _assignmentSubs.values) {
      sub.cancel();
    }
    _assignmentSubs.clear();
  }

  /*
   * الخروج يوقف الاستماع ويمسح الحالة **في الذاكرة فقط**.
   *
   * 🔴 الحدّ المحفوظ على الجهاز لا يُمَس: مسحه كان سيجعل كل دخول لاحق
   * يبدأ خط أساس جديدًا، فتضيع كل الأحداث التي وقعت بين الجلستين — وهو
   * عكس المطلوب تمامًا.
   */
  void _teardown() {
    _teardownSubscriptions();
    _checkpoint.clear();
    _preferences = const EventNotificationPreferences.none();
  }

  @override
  void dispose() {
    _teardownSubscriptions();
    super.dispose();
  }
}

/// حدث أكاديمي رُصد، جاهزًا للتحويل إلى إشعار.
class _DetectedEvent {
  const _DetectedEvent({
    required this.at,
    required this.notificationId,
    required this.type,
    required this.title,
    required this.body,
    this.courseId,
    this.postId,
    this.assignmentId,
  });

  final DateTime at;
  final String notificationId;
  final String type;
  final String title;
  final String body;
  final String? courseId;
  final String? postId;
  final String? assignmentId;
}
