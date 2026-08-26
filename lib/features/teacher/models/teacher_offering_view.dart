import '../../admin/models/admin_student_model.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/course_offering_model.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../../semesters/models/semester_model.dart';

/// نماذج عرض مشتقة لواجهة المعلّم، تُبنى في الذاكرة ولا تُخزَّن.
///
/// تتبع نمط StudentCourseView: الطرح وحده لا يكفي للعرض — هو يشير إلى مساق
/// دائم وإلى فصل دراسي — فيُجمع الثلاثة مرة واحدة بدل أن تبحث كل شاشة في
/// خرائط.

/// طرح مسند إلى المعلّم، جاهز للعرض.
///
/// [course] و [semester] قد تكونا null إذا حُذف المستند المرجعي أو لم يصل
/// بعد؛ العرض يبقى ممكنًا بحقول الطرح نفسه.
class TeacherOfferingView {
  const TeacherOfferingView({
    required this.offering,
    this.course,
    this.semester,
  });

  final CourseOfferingModel offering;
  final CourseModel? course;
  final SemesterModel? semester;

  String get offeringId => offering.id;
  String get courseId => offering.courseId;
  String get semesterId => offering.semesterId;
  String get section => offering.section;
  String get status => offering.status;
  bool get isActive => offering.isActive;

  String get courseCode => course?.courseCode ?? '';
  String get title => course?.title ?? '';
  String get description => course?.description ?? '';
  int? get creditHours => course?.creditHours;

  String get semesterName => semester?.semesterName ?? '';

  /// عنوان يصلح للعرض دائمًا.
  ///
  /// إذا لم يصل مستند المساق بعد يُعرض رمز الطرح بدل سطر فارغ: المعرّف
  /// معلومة ناقصة لكنه ليس ادّعاءً.
  String get displayTitle {
    if (title.isNotEmpty && courseCode.isNotEmpty) return '$courseCode — $title';
    if (title.isNotEmpty) return title;
    if (courseCode.isNotEmpty) return courseCode;
    return offering.courseId;
  }
}

/// طالب واحد في قائمة طرح، من منظور المعلّم.
///
/// [student] قد يكون null: مستند المستخدم قد يكون محذوفًا أو غير مقروء،
/// والقائمة يجب أن تبقى صحيحة العدد في الحالتين — التسجيل هو الحقيقة، لا
/// اسم الطالب.
class TeacherRosterEntry {
  const TeacherRosterEntry({required this.enrollment, this.student});

  final EnrollmentModel enrollment;
  final AdminStudentModel? student;

  String get userId => enrollment.userId;
  int get attemptNumber => enrollment.attemptNumber;
  bool get isRetake => enrollment.isRetake;
  String? get completionStatus => enrollment.completionStatus;
  String? get grade => enrollment.grade;

  String get studentId => student?.studentId ?? '';

  /// null يعني أن الاسم غير متاح، فتقرر الواجهة ماذا تعرض بدله.
  String? get fullName {
    final name = student?.fullName.trim() ?? '';
    return name.isEmpty ? null : name;
  }
}
