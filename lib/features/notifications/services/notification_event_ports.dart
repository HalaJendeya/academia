// lib/features/notifications/services/notification_event_ports.dart

import '../../assignments/models/course_assignment_model.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../../shared_space/models/post_model.dart';

/// تفضيلات الإشعارات التي يحتاجها كشف الأحداث.
class EventNotificationPreferences {
  const EventNotificationPreferences({
    required this.sharedSpace,
    required this.assignments,
  });

  /// افتراض آمن حين يتعذّر قراءة التفضيلات: لا إزعاج.
  const EventNotificationPreferences.none()
      : sharedSpace = false,
        assignments = false;

  final bool sharedSpace;
  final bool assignments;
}

/*
 * كل ما يحتاجه كشف الأحداث من Firestore، خلف واجهة واحدة.
 *
 * 🔴 كل استعلام هنا استعلام **مأذون للطالب أصلًا**:
 *
 *   - enrollments حيث userId == أنا  → صفوفي أنا، تسمح بها القاعدة.
 *   - posts لمساق مسجَّل فيه          → نفس استعلام تغذية المساحة المشتركة.
 *   - assignments لشُعبة مسجَّل فيها   → نفس استعلام تبويب الواجبات.
 *   - كتابة إشعار لنفسي              → recipientId == هويتي.
 *
 * لا استعلام واحد عن زميل: لا مستندات مستخدمين آخرين، ولا صفوف تسجيلهم.
 * الطالب يكتشف ما يخصّه هو، ولا يكتشف أحدٌ المستلمين.
 *
 * الواجهة موجودة أيضًا لتُختبر دورة الكشف كاملة بلا Firebase — نفس نمط
 * FcmGateway.
 */
abstract class NotificationEventFeeds {
  /// هوية المستخدم المصادَق حاليًا، أو null.
  String? get currentUid;

  Stream<List<EnrollmentModel>> watchMyEnrollments();

  Stream<List<PostModel>> watchPostsForCourse(String courseId);

  Stream<List<CourseAssignmentModel>> watchOfferingAssignments(
    String offeringId,
  );

  /// تفضيلات المستخدم الحالي، من مستنده هو.
  Future<EventNotificationPreferences> readMyPreferences();

  /// ينشئ إشعارًا لنفس المستخدم بمعرّف محدَّد سلفًا.
  ///
  /// يعيد false إن كان موجودًا مسبقًا — دون المساس به.
  Future<bool> createSelfNotificationIfAbsent({
    required String notificationId,
    required String type,
    required String title,
    required String body,
    String? courseId,
    String? postId,
    String? assignmentId,
  });
}

/// أين تُحفظ نقطة البداية التي لا يُشعَر بما قبلها.
///
/// 🔴 الحدّ لكل (حساب، فئة) لا لكل حساب.
///
/// المنشورات والواجبات تدفّقان مستقلان يصلان بترتيب غير مضمون؛ بحدٍّ
/// مشترك يكتم تقدّمُ أحدهما أحداثَ الآخر الأقدم منه. والفصل يجعل كلًّا
/// منهما يتقدّم بمعزل عن صاحبه.
abstract class NotificationCheckpointStore {
  Future<DateTime?> read(String uid, String category);
  Future<void> write(String uid, String category, DateTime at);
  Future<void> clear(String uid, String category);
}
