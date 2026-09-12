// lib/features/notifications/services/firebase_notification_event_feeds.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/notification_preference_keys.dart';
import '../../assignments/models/course_assignment_model.dart';
import '../../assignments/services/course_assignment_service.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../../enrollments/services/enrollment_service.dart';
import '../../shared_space/models/post_model.dart';
import '../../shared_space/services/post_service.dart';
import 'notification_event_ports.dart';

/// التنفيذ الحقيقي فوق الخدمات القائمة.
///
/// 🔴 لا استعلام جديد هنا: كل تدفّق يعيد استعمال الدالة نفسها التي تستعملها
/// الشاشات، فلا فهرس Firestore جديد ولا صلاحية جديدة.
class FirebaseNotificationEventFeeds implements NotificationEventFeeds {
  FirebaseNotificationEventFeeds({
    EnrollmentService? enrollments,
    PostService? posts,
    CourseAssignmentService? assignments,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _enrollments = enrollments ?? EnrollmentService(),
        _posts = posts ?? PostService(),
        _assignments = assignments ?? CourseAssignmentService(),
        _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final EnrollmentService _enrollments;
  final PostService _posts;
  final CourseAssignmentService _assignments;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Stream<List<EnrollmentModel>> watchMyEnrollments() =>
      _enrollments.watchMyEnrollments();

  @override
  Stream<List<PostModel>> watchPostsForCourse(String courseId) =>
      _posts.watchPostsForCourse(courseId);

  @override
  Stream<List<CourseAssignmentModel>> watchOfferingAssignments(
    String offeringId,
  ) =>
      _assignments.watchOfferingAssignments(offeringId);

  @override
  Future<EventNotificationPreferences> readMyPreferences() async {
    final uid = currentUid;
    if (uid == null) return const EventNotificationPreferences.none();

    // مستند المستخدم نفسه — قراءة مأذونة بالكامل.
    final doc = await _db.collection('users').doc(uid).get();
    final prefs = doc.data()?['notificationPreferences'] as Map?;

    return EventNotificationPreferences(
      sharedSpace:
          prefs?[NotificationPreferenceKeys.sharedSpaceNotifications] == true,
      /*
       * إشعارات الواجبات تتبع «تذكيرات الواجبات» الموجود أصلًا في شاشة
       * الإعدادات (المفتاح المخزَّن: taskReminders).
       *
       * لا تفضيل جديد ولا شاشة جديدة: التفضيل ظاهر للطالبة وتتحكم به،
       * وافتراضه true مطابق لما يفترضه NotificationSettings.fromFirestore
       * لهذا المفتاح بالضبط — فلا يختلف ما يقوله الإعداد عمّا يفعله
       * التطبيق.
       */
      assignments: prefs?[NotificationPreferenceKeys.taskReminders] != false,
    );
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
    final uid = currentUid;
    if (uid == null) return false;

    /*
     * إنشاء فقط، بمعرّف حتمي.
     *
     * قاعدة notifications تسمح بالإنشاء (recipientId == هويتي) ولا تسمح
     * بالتحديث إلا لـ isRead. فإن كان المستند موجودًا صارت هذه الكتابة
     * تحديثًا وتُرفض — وهذا بالضبط ما نريد: لا تكرار، ولا إعادة ضبط
     * إشعار قرأته الطالبة إلى "غير مقروء".
     *
     * لذلك permission-denied هنا تُقرأ كـ"موجود مسبقًا" لا كعطل.
     */
    try {
      await _db.collection('notifications').doc(notificationId).set({
        'recipientId': uid,
        'type': type,
        'title': title,
        'body': body,
        // العلامة على القيمة لا على المفتاح: مفتاح غائب أصدق من قيمة null.
        'courseId': ?courseId,
        'postId': ?postId,
        'assignmentId': ?assignmentId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return false;
      rethrow;
    }
  }
}

/// نقطة البداية محفوظة على الجهاز، لكل حساب على حدة.
///
/// محليّة عمدًا: الحدّ يعني "ما رآه هذا الجهاز"، وجهاز جديد يجب ألا يعيد
/// سرد تاريخ الفصل كإشعارات جديدة. وحفظها في Firestore كان سيتطلب حقلًا
/// جديدًا وقاعدة جديدة بلا فائدة تُذكر.
class SharedPreferencesCheckpointStore implements NotificationCheckpointStore {
  const SharedPreferencesCheckpointStore();

  static String _key(String uid, String category) =>
      'notificationCheckpoint_${category}_$uid';

  @override
  Future<DateTime?> read(String uid, String category) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_key(uid, category));
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> write(String uid, String category, DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(uid, category), at.millisecondsSinceEpoch);
  }

  @override
  Future<void> clear(String uid, String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(uid, category));
  }
}
