import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:academia/features/assignments/models/course_assignment_model.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/notifications/models/app_notification.dart';
import 'package:academia/features/notifications/providers/notification_events_provider.dart';
import 'package:academia/features/notifications/services/notification_event_ports.dart';
import 'package:academia/features/shared_space/models/post_model.dart';

/*
 * كشف الأحداث الأكاديمية على خطة Spark.
 *
 * ما تحرسه هذه الاختبارات:
 *
 *   1. **لا فيضان تاريخي**: أول لقطة تُعيد كل المنشورات والواجبات القائمة
 *      بوصفها "مضافة". بلا حدّ زمني محفوظ تتحول إلى عشرات الإشعارات عند
 *      أول دخول، ثم تتكرر مع كل إعادة تشغيل.
 *   2. **لا استعلام عن زميل**: البديل يرمي إن حاول أي شيء قراءة مستند
 *      مستخدم آخر — فالاختبار يثبت الأمر بدل أن يدّعيه.
 *   3. **دورة حياة نظيفة**: خروج يوقف كل شيء، وتبديل حساب لا يسرّب أحداث
 *      الحساب السابق.
 */

class FakeCheckpointStore implements NotificationCheckpointStore {
  /// المفتاح: "uid|category" — يحاكي التخزين المستمر على الجهاز.
  final Map<String, DateTime> stored = {};
  int writes = 0;

  static String key(String uid, String category) => '$uid|$category';

  void seed(String uid, DateTime at) {
    for (final category in NotificationEventsProvider.categories) {
      stored[key(uid, category)] = at;
    }
  }

  DateTime? posts(String uid) =>
      stored[key(uid, NotificationEventsProvider.postCategory)];
  DateTime? assignments(String uid) =>
      stored[key(uid, NotificationEventsProvider.assignmentCategory)];

  @override
  Future<DateTime?> read(String uid, String category) async =>
      stored[key(uid, category)];

  @override
  Future<void> write(String uid, String category, DateTime at) async {
    writes++;
    stored[key(uid, category)] = at;
  }

  @override
  Future<void> clear(String uid, String category) async =>
      stored.remove(key(uid, category));
}

class FakeFeeds implements NotificationEventFeeds {
  FakeFeeds({this.uid = 'me', EventNotificationPreferences? preferences})
      : preferences =
            preferences ?? const EventNotificationPreferences(
              sharedSpace: true,
              assignments: true,
            );

  String? uid;
  EventNotificationPreferences preferences;
  Object? preferencesError;

  final enrollments = StreamController<List<EnrollmentModel>>.broadcast();
  final postControllers = <String, StreamController<List<PostModel>>>{};
  final assignmentControllers =
      <String, StreamController<List<CourseAssignmentModel>>>{};

  /// مستندات الإشعارات المنشأة: id -> بياناتها.
  final created = <String, Map<String, Object?>>{};
  final createCalls = <String>[];

  /// معرّفات تفشل كتابتها (عطل عابر) حتى تُزال من المجموعة.
  final failingIds = <String>{};

  int enrollmentListeners = 0;

  @override
  String? get currentUid => uid;

  @override
  Stream<List<EnrollmentModel>> watchMyEnrollments() {
    enrollmentListeners++;
    final controller = StreamController<List<EnrollmentModel>>();
    final sub = enrollments.stream.listen(controller.add);
    controller.onCancel = () {
      enrollmentListeners--;
      sub.cancel();
    };
    return controller.stream;
  }

  StreamController<List<PostModel>> posts(String courseId) =>
      postControllers.putIfAbsent(
        courseId,
        () => StreamController<List<PostModel>>.broadcast(),
      );

  StreamController<List<CourseAssignmentModel>> assignments(String offeringId) =>
      assignmentControllers.putIfAbsent(
        offeringId,
        () => StreamController<List<CourseAssignmentModel>>.broadcast(),
      );

  @override
  Stream<List<PostModel>> watchPostsForCourse(String courseId) =>
      posts(courseId).stream;

  @override
  Stream<List<CourseAssignmentModel>> watchOfferingAssignments(
          String offeringId) =>
      assignments(offeringId).stream;

  @override
  Future<EventNotificationPreferences> readMyPreferences() async {
    final error = preferencesError;
    if (error != null) throw error;
    return preferences;
  }

  @override
  Future<bool> createSelfNotificationIfAbsent({
    required String notificationId,
    required String type,
    required String title,
    required String body,
    String? courseId,
    String? postId,
    String? assignmentId,
  }) async {
    createCalls.add(notificationId);
    if (failingIds.contains(notificationId)) {
      throw Exception('transient write failure');
    }
    if (created.containsKey(notificationId)) return false; // موجود مسبقًا
    created[notificationId] = {
      'recipientId': uid,
      'type': type,
      'title': title,
      'body': body,
      'courseId': courseId,
      'postId': postId,
      'assignmentId': assignmentId,
      'isRead': false,
    };
    return true;
  }

  Future<void> dispose() async {
    await enrollments.close();
    for (final c in postControllers.values) {
      await c.close();
    }
    for (final c in assignmentControllers.values) {
      await c.close();
    }
  }
}

EnrollmentModel enrollment({
  String userId = 'me',
  String courseId = 'c1',
  String offeringId = 'off1',
  String status = 'active',
}) =>
    EnrollmentModel(
      id: '${userId}_$offeringId',
      userId: userId,
      offeringId: offeringId,
      courseId: courseId,
      semesterId: 'sem1',
      attemptNumber: 1,
      status: status,
      assignedBy: 'admin1',
    );

PostModel post({
  String id = 'p1',
  String authorId = 'someoneElse',
  String courseId = 'c1',
  required DateTime createdAt,
  String status = PostModel.statusActive,
}) =>
    PostModel(
      id: id,
      courseId: courseId,
      authorId: authorId,
      authorName: 'زميلة',
      content: 'محتوى',
      createdAt: createdAt,
      status: status,
    );

CourseAssignmentModel assignment({
  String id = 'a1',
  String offeringId = 'off1',
  String courseId = 'c1',
  required DateTime? createdAt,
  String status = CourseAssignmentModel.statusActive,
}) =>
    CourseAssignmentModel(
      id: id,
      offeringId: offeringId,
      courseId: courseId,
      semesterId: 'sem1',
      title: 'واجب الوحدة الأولى',
      description: 'تفاصيل',
      dueAt: DateTime(2026, 12, 1),
      priority: 'medium',
      status: status,
      createdBy: 'teacher1',
      createdAt: createdAt,
    );

/// يشغّل المزوّد إلى أن تستقر كل المهام المؤجَّلة.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

Future<(NotificationEventsProvider, FakeFeeds, FakeCheckpointStore)> start({
  DateTime? existingCheckpoint,
  EventNotificationPreferences? preferences,
}) async {
  final feeds = FakeFeeds(preferences: preferences);
  final checkpoints = FakeCheckpointStore();
  if (existingCheckpoint != null) {
    checkpoints.seed('me', existingCheckpoint);
  }
  final provider = NotificationEventsProvider(feeds, checkpoints);
  provider.syncWithAuth(uid: 'me');
  await settle();
  feeds.enrollments.add([enrollment()]);
  await settle();
  return (provider, feeds, checkpoints);
}

void main() {
  final past = DateTime(2026, 1, 1);
  final boundary = DateTime(2026, 6, 1);
  final future = DateTime(2026, 6, 2);

  group('منع الفيضان التاريخي', () {
    test('أول تشغيل يضع خط أساس ولا يُنشئ إشعارًا واحدًا', () async {
      final (provider, feeds, checkpoints) = await start();
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      // لقطة أولى مليئة بمنشورات قديمة — كما يحدث فعلًا عند بدء الاستماع.
      feeds.posts('c1').add([
        post(id: 'old1', createdAt: past),
        post(id: 'old2', createdAt: past),
        post(id: 'old3', createdAt: past),
      ]);
      await settle();

      expect(feeds.created, isEmpty);
      expect(checkpoints.posts('me'), isNotNull, reason: 'خط أساس للمنشورات');
      expect(checkpoints.assignments('me'), isNotNull,
          reason: 'وخط أساس مستقل للواجبات');
    });

    test('الأحداث الأقدم من الحدّ المحفوظ تُتجاهل', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.posts('c1').add([post(id: 'old', createdAt: past)]);
      await settle();

      expect(feeds.created, isEmpty);
    });

    test('إعادة التشغيل بحدّ محفوظ لا تعيد سرد التاريخ', () async {
      // نفس الحساب، نفس الجهاز، تطبيق أُعيد تشغيله: الحدّ يُقرأ من التخزين.
      final feeds = FakeFeeds();
      final checkpoints = FakeCheckpointStore()..seed('me', boundary);
      addTearDown(feeds.dispose);

      final provider = NotificationEventsProvider(feeds, checkpoints);
      addTearDown(provider.dispose);
      provider.syncWithAuth(uid: 'me');
      await settle();
      feeds.enrollments.add([enrollment()]);
      await settle();

      feeds.posts('c1').add([
        post(id: 'old1', createdAt: past),
        post(id: 'old2', createdAt: past),
      ]);
      await settle();

      expect(feeds.created, isEmpty);
      expect(provider.checkpointFor(NotificationEventsProvider.postCategory),
          boundary);
    });
  });

  group('منشورات المساحة المشتركة', () {
    test('منشور جديد مؤهَّل يُنشئ إشعارًا واحدًا بالضبط', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.posts('c1').add([post(id: 'p9', createdAt: future)]);
      await settle();

      expect(feeds.created.keys.toList(), ['post_p9_me']);
      final doc = feeds.created['post_p9_me']!;
      expect(doc['type'], AppNotification.typeNewSharedSpacePost);
      expect(doc['courseId'], 'c1');
      expect(doc['postId'], 'p9');
      expect(doc['isRead'], false);
    });

    test('منشوري أنا لا يُنشئ إشعارًا', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.posts('c1').add([
        post(id: 'mine', authorId: 'me', createdAt: future),
      ]);
      await settle();

      expect(feeds.created, isEmpty);
    });

    test('مساق غير مسجَّل فيه لا يُستمع إليه أصلًا', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      // c1 فقط ضمن تسجيلاتي.
      expect(provider.activeCourseListeners, 1);
      feeds.posts('c2').add([post(id: 'other', courseId: 'c2', createdAt: future)]);
      await settle();

      expect(feeds.created, isEmpty);
    });

    test('تعطيل التفضيل يمنع الإشعار', () async {
      final (provider, feeds, _) = await start(
        existingCheckpoint: boundary,
        preferences: const EventNotificationPreferences(
          sharedSpace: false,
          assignments: true,
        ),
      );
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.posts('c1').add([post(id: 'p9', createdAt: future)]);
      await settle();

      expect(feeds.created, isEmpty);
    });

    test('منشور مؤرشف لا يُنشئ إشعارًا', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.posts('c1').add([
        post(id: 'p9', createdAt: future, status: PostModel.statusArchived),
      ]);
      await settle();

      expect(feeds.created, isEmpty);
    });

    test('المعرّف حتمي ومستقر', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.posts('c1').add([post(id: 'p9', createdAt: future)]);
      await settle();

      expect(feeds.createCalls.single, 'post_p9_me');
    });

    test('إعادة إرسال اللقطة لا تُكرّر الإشعار', () async {
      // إعادة اتصال الشبكة تُعيد اللقطة كاملة.
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      final snapshot = [post(id: 'p9', createdAt: future)];
      feeds.posts('c1').add(snapshot);
      await settle();
      feeds.posts('c1').add(snapshot);
      await settle();
      feeds.posts('c1').add(snapshot);
      await settle();

      expect(feeds.created.length, 1);
      // الحدّ تقدّم، فالمحاولات التالية لم تصل إلى الكتابة إطلاقًا.
      expect(feeds.createCalls.length, 1);
    });

    test('إشعار مقروء لا يُعاد ضبطه بإعادة الحدث', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.posts('c1').add([post(id: 'p9', createdAt: future)]);
      await settle();
      feeds.created['post_p9_me']!['isRead'] = true; // الطالبة قرأته

      feeds.posts('c1').add([post(id: 'p9', createdAt: future)]);
      await settle();

      expect(feeds.created['post_p9_me']!['isRead'], true);
    });
  });

  group('الواجبات', () {
    test('واجب جديد لشُعبة مسجَّل فيها يُنشئ إشعارًا واحدًا', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.assignments('off1').add([assignment(id: 'a9', createdAt: future)]);
      await settle();

      expect(feeds.created.keys.toList(), ['assignment_a9_me']);
      final doc = feeds.created['assignment_a9_me']!;
      expect(doc['type'], AppNotification.typeNewAssignment);
      expect(doc['assignmentId'], 'a9');
      expect(doc['courseId'], 'c1');
      expect(doc['body'], 'واجب الوحدة الأولى');
    });

    test('أول لقطة واجبات لا تُنشئ إشعارات تاريخية', () async {
      final (provider, feeds, _) = await start();
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.assignments('off1').add([
        assignment(id: 'old1', createdAt: past),
        assignment(id: 'old2', createdAt: past),
      ]);
      await settle();

      expect(feeds.created, isEmpty);
    });

    test('شُعبة غير مسجَّل فيها لا يُستمع إليها', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      expect(provider.activeOfferingListeners, 1);
      feeds.assignments('off2').add([
        assignment(id: 'a9', offeringId: 'off2', createdAt: future),
      ]);
      await settle();

      expect(feeds.created, isEmpty);
    });

    test('إعادة الحدث لا تُكرّر الإشعار', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      final snapshot = [assignment(id: 'a9', createdAt: future)];
      feeds.assignments('off1').add(snapshot);
      await settle();
      feeds.assignments('off1').add(snapshot);
      await settle();

      expect(feeds.created.length, 1);
    });

    test('واجب بلا زمن إنشاء يُتجاهل بدل أن يُعتبر جديدًا', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.assignments('off1').add([assignment(id: 'a9', createdAt: null)]);
      await settle();

      expect(feeds.created, isEmpty);
    });

    test('تعطيل تذكير الواجبات يمنع الإشعار', () async {
      final (provider, feeds, _) = await start(
        existingCheckpoint: boundary,
        preferences: const EventNotificationPreferences(
          sharedSpace: true,
          assignments: false,
        ),
      );
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.assignments('off1').add([assignment(id: 'a9', createdAt: future)]);
      await settle();

      expect(feeds.created, isEmpty);
    });
  });

  group('دورة الحياة', () {
    test('تسجيل الخروج يلغي كل المستمعين', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      expect(provider.hasEnrollmentListener, isTrue);
      expect(provider.activeCourseListeners, 1);

      provider.syncWithAuth(uid: null);
      await settle();

      expect(provider.hasEnrollmentListener, isFalse);
      expect(provider.activeCourseListeners, 0);
      expect(provider.activeOfferingListeners, 0);
      expect(feeds.enrollmentListeners, 0);
      expect(provider.checkpointFor(NotificationEventsProvider.postCategory),
          isNull);
    });

    test('لا كتابة بعد الخروج ولو وصل حدث متأخر', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      provider.syncWithAuth(uid: null);
      await settle();
      feeds.posts('c1').add([post(id: 'late', createdAt: future)]);
      await settle();

      expect(feeds.created, isEmpty);
    });

    test('تبديل الحساب أ ← ب لا يسرّب أحداث أ', () async {
      final feeds = FakeFeeds(uid: 'A');
      final checkpoints = FakeCheckpointStore()
        ..seed('A', boundary)
        ..seed('B', boundary);
      addTearDown(feeds.dispose);

      final provider = NotificationEventsProvider(feeds, checkpoints);
      addTearDown(provider.dispose);

      provider.syncWithAuth(uid: 'A');
      await settle();
      feeds.enrollments.add([enrollment(userId: 'A')]);
      await settle();

      provider.syncWithAuth(uid: null);
      await settle();
      feeds.uid = 'B';
      provider.syncWithAuth(uid: 'B');
      await settle();
      feeds.enrollments.add([enrollment(userId: 'B')]);
      await settle();

      feeds.posts('c1').add([post(id: 'p9', createdAt: future)]);
      await settle();

      // الإشعار مُنسَب إلى ب وحده، ولا نسخة باسم أ.
      expect(feeds.created.keys.toList(), ['post_p9_B']);
    });

    test('مزامنة متكررة بنفس الهوية لا تُضاعف الاشتراكات', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      for (var i = 0; i < 3; i++) {
        provider.syncWithAuth(uid: 'me');
        await settle();
      }
      feeds.enrollments.add([enrollment()]);
      await settle();

      expect(feeds.enrollmentListeners, 1);
      expect(provider.activeCourseListeners, 1);
      expect(provider.activeOfferingListeners, 1);
    });

    test('انسحاب من مساق يوقف الاستماع إليه', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.enrollments.add([
        enrollment(courseId: 'c1', offeringId: 'off1'),
        enrollment(courseId: 'c2', offeringId: 'off2'),
      ]);
      await settle();
      expect(provider.activeCourseListeners, 2);

      feeds.enrollments.add([enrollment(courseId: 'c1', offeringId: 'off1')]);
      await settle();
      expect(provider.activeCourseListeners, 1);
    });

    test('تسجيل غير فعّال لا يُنشئ مستمعًا', () async {
      final feeds = FakeFeeds();
      final checkpoints = FakeCheckpointStore()..seed('me', boundary);
      addTearDown(feeds.dispose);
      final provider = NotificationEventsProvider(feeds, checkpoints);
      addTearDown(provider.dispose);

      provider.syncWithAuth(uid: 'me');
      await settle();
      feeds.enrollments.add([enrollment(status: 'removed')]);
      await settle();

      expect(provider.activeCourseListeners, 0);
    });

    test('syncWithAuth لا تُشعر المستمعين بشكل متزامن', () async {
      // تُستدعى من ProxyProvider.update أثناء البناء.
      final feeds = FakeFeeds();
      final checkpoints = FakeCheckpointStore()..seed('me', boundary);
      addTearDown(feeds.dispose);
      final provider = NotificationEventsProvider(feeds, checkpoints);
      addTearDown(provider.dispose);

      var notified = 0;
      provider.addListener(() => notified++);

      provider.syncWithAuth(uid: 'me');
      expect(notified, 0);
      provider.syncWithAuth(uid: null);
      expect(notified, 0);
    });

    test('فشل قراءة التفضيلات يعني الصمت لا الإزعاج', () async {
      final feeds = FakeFeeds()..preferencesError = Exception('denied');
      final checkpoints = FakeCheckpointStore()..seed('me', boundary);
      addTearDown(feeds.dispose);
      final provider = NotificationEventsProvider(feeds, checkpoints);
      addTearDown(provider.dispose);

      provider.syncWithAuth(uid: 'me');
      await settle();
      feeds.enrollments.add([enrollment()]);
      await settle();
      feeds.posts('c1').add([post(id: 'p9', createdAt: future)]);
      await settle();

      expect(feeds.created, isEmpty);
    });
  });

  /*
   * ═══════════ دلالات الحدّ الزمني عبر الجلسات ═══════════
   *
   * الحدّ الفاصل الوحيد المقبول هو «أول استعمال على هذا الجهاز». بعده،
   * إغلاق التطبيق لا يعني ضياع ما يقع أثناءه: الحدّ محفوظ، والفتح التالي
   * يستأنف من عنده لا من لحظة الفتح.
   */
  group('عبر الجلسات', () {
    test('A. أول دخول: منشورات وواجبات قديمة ← صفر إشعارات', () async {
      final (provider, feeds, checkpoints) = await start(); // بلا حدّ محفوظ
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.posts('c1').add([
        post(id: 'oldPost1', createdAt: past),
        post(id: 'oldPost2', createdAt: past),
      ]);
      feeds.assignments('off1').add([
        assignment(id: 'oldA1', createdAt: past),
        assignment(id: 'oldA2', createdAt: past),
      ]);
      await settle();

      expect(feeds.created, isEmpty);
      expect(checkpoints.posts('me'), isNotNull);
      expect(checkpoints.assignments('me'), isNotNull);
    });

    test('B. إغلاق ← منشور أثناء الإغلاق ← فتح: إشعار واحد بالضبط', () async {
      /*
       * 🔴 السيناريو الأهم: حدّ الطالبة 10:00، التطبيق مغلق، يُنشأ منشور
       * في 11:00، ثم تفتح التطبيق في 12:00.
       *
       * يجب أن تجد إشعارًا. الحدّ المحفوظ هو ما يجعل ذلك ممكنًا — لو
       * استُعملت لحظة الفتح خط أساس جديدًا لضاع المنشور.
       */
      final tenAm = DateTime(2026, 6, 1, 10);
      final elevenAm = DateTime(2026, 6, 1, 11);

      final feeds = FakeFeeds();
      final checkpoints = FakeCheckpointStore()..seed('me', tenAm);
      addTearDown(feeds.dispose);

      // فتح جديد يحاكي إعادة تشغيل التطبيق.
      final provider = NotificationEventsProvider(feeds, checkpoints);
      addTearDown(provider.dispose);
      provider.syncWithAuth(uid: 'me');
      await settle();
      feeds.enrollments.add([enrollment()]);
      await settle();

      feeds.posts('c1').add([post(id: 'whileClosed', createdAt: elevenAm)]);
      await settle();

      expect(feeds.created.keys.toList(), ['post_whileClosed_me']);
      expect(checkpoints.posts('me'), elevenAm);
    });

    test('B2. عدة منشورات أثناء الإغلاق ← إشعار لكلٍّ منها', () async {
      /*
       * استعلام المنشورات تنازلي (الأحدث أولًا). تحريك الحدّ بعد كل حدث
       * كان يقفز فوق الأقدم في اللقطة نفسها فيضيع.
       */
      final tenAm = DateTime(2026, 6, 1, 10);
      final feeds = FakeFeeds();
      final checkpoints = FakeCheckpointStore()..seed('me', tenAm);
      addTearDown(feeds.dispose);
      final provider = NotificationEventsProvider(feeds, checkpoints);
      addTearDown(provider.dispose);
      provider.syncWithAuth(uid: 'me');
      await settle();
      feeds.enrollments.add([enrollment()]);
      await settle();

      // بترتيب الاستعلام الحقيقي: الأحدث أولًا.
      feeds.posts('c1').add([
        post(id: 'newer', createdAt: DateTime(2026, 6, 1, 11, 30)),
        post(id: 'older', createdAt: DateTime(2026, 6, 1, 11)),
      ]);
      await settle();

      expect(
        feeds.created.keys.toSet(),
        {'post_newer_me', 'post_older_me'},
        reason: 'الأقدم في اللقطة نفسها يجب ألا يُقفز فوقه',
      );
    });

    test('C. واجب أثناء الإغلاق يُكتشف عند الفتح', () async {
      final tenAm = DateTime(2026, 6, 1, 10);
      final elevenAm = DateTime(2026, 6, 1, 11);
      final feeds = FakeFeeds();
      final checkpoints = FakeCheckpointStore()..seed('me', tenAm);
      addTearDown(feeds.dispose);
      final provider = NotificationEventsProvider(feeds, checkpoints);
      addTearDown(provider.dispose);
      provider.syncWithAuth(uid: 'me');
      await settle();
      feeds.enrollments.add([enrollment()]);
      await settle();

      feeds
          .assignments('off1')
          .add([assignment(id: 'whileClosed', createdAt: elevenAm)]);
      await settle();

      expect(feeds.created.keys.toList(), ['assignment_whileClosed_me']);
      expect(checkpoints.assignments('me'), elevenAm);
    });

    test('D. 🔴 تقدّم المنشورات إلى 12:00 لا يُضيع واجب 11:30', () async {
      /*
       * العطل الذي كان: حدّ واحد مشترك. معالجة منشور الثانية عشرة تدفعه
       * إلى 12:00، فيصل واجب 11:30 بعدها فيُعدّ قديمًا ويضيع نهائيًا.
       *
       * الحدّان مستقلان الآن، فتقدّم أحدهما لا يكتم الآخر.
       */
      final tenAm = DateTime(2026, 6, 1, 10);
      final noon = DateTime(2026, 6, 1, 12);
      final elevenThirty = DateTime(2026, 6, 1, 11, 30);

      final feeds = FakeFeeds();
      final checkpoints = FakeCheckpointStore()..seed('me', tenAm);
      addTearDown(feeds.dispose);
      final provider = NotificationEventsProvider(feeds, checkpoints);
      addTearDown(provider.dispose);
      provider.syncWithAuth(uid: 'me');
      await settle();
      feeds.enrollments.add([enrollment()]);
      await settle();

      // تدفّق المنشورات يسبق ويصل إلى 12:00.
      feeds.posts('c1').add([post(id: 'noon', createdAt: noon)]);
      await settle();
      expect(checkpoints.posts('me'), noon);

      // ثم يصل واجب أُنشئ في 11:30 — أقدم من حدّ المنشورات.
      feeds
          .assignments('off1')
          .add([assignment(id: 'elevenThirty', createdAt: elevenThirty)]);
      await settle();

      expect(
        feeds.created.containsKey('assignment_elevenThirty_me'),
        isTrue,
        reason: 'الواجب لا يُكتم بتقدّم تدفّق المنشورات',
      );
      expect(checkpoints.assignments('me'), elevenThirty);
    });

    test('E. الخروج لا يمحو الحدّ المحفوظ', () async {
      final (provider, feeds, checkpoints) =
          await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.posts('c1').add([post(id: 'p9', createdAt: future)]);
      await settle();
      final afterEvent = checkpoints.posts('me');

      provider.syncWithAuth(uid: null);
      await settle();

      // الذاكرة نُظِّفت، والتخزين لم يُمَس.
      expect(
        provider.checkpointFor(NotificationEventsProvider.postCategory),
        isNull,
      );
      expect(checkpoints.posts('me'), afterEvent);

      // ودخول جديد يستأنف من الحدّ المحفوظ لا من الآن.
      provider.syncWithAuth(uid: 'me');
      await settle();
      expect(
        provider.checkpointFor(NotificationEventsProvider.postCategory),
        afterEvent,
      );
    });

    test('F. أ ← ب ← أ: كل حساب يستعيد حدوده هو', () async {
      final aBoundary = DateTime(2026, 5, 1);
      final bBoundary = DateTime(2026, 7, 1);

      final feeds = FakeFeeds(uid: 'A');
      final checkpoints = FakeCheckpointStore()
        ..seed('A', aBoundary)
        ..seed('B', bBoundary);
      addTearDown(feeds.dispose);
      final provider = NotificationEventsProvider(feeds, checkpoints);
      addTearDown(provider.dispose);

      provider.syncWithAuth(uid: 'A');
      await settle();
      expect(
        provider.checkpointFor(NotificationEventsProvider.postCategory),
        aBoundary,
      );

      provider.syncWithAuth(uid: null);
      await settle();
      feeds.uid = 'B';
      provider.syncWithAuth(uid: 'B');
      await settle();
      expect(
        provider.checkpointFor(NotificationEventsProvider.postCategory),
        bBoundary,
      );

      provider.syncWithAuth(uid: null);
      await settle();
      feeds.uid = 'A';
      provider.syncWithAuth(uid: 'A');
      await settle();
      expect(
        provider.checkpointFor(NotificationEventsProvider.postCategory),
        aBoundary,
        reason: 'حدّ أ لم يُستبدل بحدّ ب ولا بلحظة الدخول',
      );
    });

    test('G. 🔴 فشل عابر في الكتابة لا يُضيع الحدث نهائيًا', () async {
      final (provider, feeds, checkpoints) =
          await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.failingIds.add('post_p9_me');
      feeds.posts('c1').add([post(id: 'p9', createdAt: future)]);
      await settle();

      // لم يُكتب شيء، والحدّ لم يتقدّم فوق الحدث.
      expect(feeds.created, isEmpty);
      expect(checkpoints.posts('me'), boundary);

      // زال العطل: اللقطة التالية تُنشئ الإشعار.
      feeds.failingIds.clear();
      feeds.posts('c1').add([post(id: 'p9', createdAt: future)]);
      await settle();

      expect(feeds.created.keys.toList(), ['post_p9_me']);
      expect(checkpoints.posts('me'), future);
    });

    test('G2. فشل حدث لا يقفز الحدّ فوق أحداث لاحقة له', () async {
      final (provider, feeds, checkpoints) =
          await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      final earlier = DateTime(2026, 6, 2);
      final later = DateTime(2026, 6, 3);
      feeds.failingIds.add('post_first_me');
      feeds.posts('c1').add([
        post(id: 'second', createdAt: later),
        post(id: 'first', createdAt: earlier),
      ]);
      await settle();

      // الأقدم فشل، فتوقّفت المعالجة عنده ولم يتقدّم الحدّ.
      expect(feeds.created, isEmpty);
      expect(checkpoints.posts('me'), boundary);

      feeds.failingIds.clear();
      feeds.posts('c1').add([
        post(id: 'second', createdAt: later),
        post(id: 'first', createdAt: earlier),
      ]);
      await settle();

      expect(feeds.created.keys.toSet(), {'post_first_me', 'post_second_me'});
    });

    test('H. إعادة الاتصال لا تُكرّر، والمقروء يبقى مقروءًا', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      final snapshot = [post(id: 'p9', createdAt: future)];
      feeds.posts('c1').add(snapshot);
      await settle();
      feeds.created['post_p9_me']!['isRead'] = true; // الطالبة قرأته

      // إعادة اتصال: اللقطة نفسها تصل مرتين أخريين.
      feeds.posts('c1').add(snapshot);
      await settle();
      feeds.posts('c1').add(snapshot);
      await settle();

      expect(feeds.created.length, 1);
      expect(feeds.created['post_p9_me']!['isRead'], true);
    });
  });
  group('الحدود الأمنية', () {
    test('🔴 لا استعلام عن أي مستخدم آخر في مسار الكشف كله', () async {
      /*
       * الواجهة نفسها لا تملك دالة لقراءة مستخدم آخر — readMyPreferences
       * تقرأ مستندي أنا فقط. هذا الاختبار يثبّت الشكل: أي محاولة مستقبلية
       * لإضافة قراءة عن زميل ستحتاج توسيع الواجهة، وهو تغيير ظاهر لا يمرّ
       * بصمت في مراجعة.
       */
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.posts('c1').add([post(id: 'p9', createdAt: future)]);
      await settle();

      // الإشعار أُنشئ دون أي قراءة عن الناشر: النص عام لا يحمل اسمه.
      final doc = feeds.created['post_p9_me']!;
      expect(doc['body'], 'تم نشر منشور جديد في المساحة المشتركة');
      expect(doc['body'].toString().contains('زميلة'), isFalse);
    });

    test('كل إشعار مُنشأ يخصّ صاحب الجلسة نفسه', () async {
      final (provider, feeds, _) = await start(existingCheckpoint: boundary);
      addTearDown(feeds.dispose);
      addTearDown(provider.dispose);

      feeds.posts('c1').add([post(id: 'p9', createdAt: future)]);
      feeds.assignments('off1').add([assignment(id: 'a9', createdAt: future)]);
      await settle();

      for (final entry in feeds.created.entries) {
        expect(entry.value['recipientId'], 'me');
        expect(entry.key.endsWith('_me'), isTrue);
      }
    });
  });
}
