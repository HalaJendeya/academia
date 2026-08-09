import '../../curriculum/models/curriculum_course_model.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../../semesters/models/semester_model.dart';
import 'course_model.dart';
import 'course_offering_model.dart';

/// نماذج عرض مشتقة، تُبنى في الذاكرة ولا تُخزَّن في Firestore.
///
/// وجودها يمنع تكرار الربط في كل شاشة: التسجيل وحده لا يكفي للعرض، فهو
/// يشير إلى طرح، والطرح يشير إلى مساق دائم وإلى فصل دراسي. تجميع الأربعة
/// هنا مرة واحدة يجعل الواجهة تقرأ حقولًا جاهزة بدل أن تبحث في خرائط.

/// محاولة واحدة للطالب في مساق، جاهزة للعرض.
///
/// [offering] و [course] و [semester] قد تكون null إذا حُذف المستند المرجعي
/// أو تعذّرت قراءته؛ العرض يبقى ممكنًا بالحقول المنسوخة في التسجيل نفسه.
class StudentCourseView {
  const StudentCourseView({
    required this.enrollment,
    this.offering,
    this.course,
    this.semester,
    this.curriculumEntry,
  });

  final EnrollmentModel enrollment;
  final CourseOfferingModel? offering;
  final CourseModel? course;
  final SemesterModel? semester;

  /// صف الخطة الدراسية المقابل، إن كان المساق ضمن خطة الطالب.
  ///
  /// null مشروع تمامًا: الطالب قد يدرس مساقًا خارج خطته.
  final CurriculumCourseModel? curriculumEntry;

  String get courseId => enrollment.courseId;
  String get offeringId => enrollment.offeringId;
  String get semesterId => enrollment.semesterId;

  int get attemptNumber => enrollment.attemptNumber;
  bool get isRetake => enrollment.isRetake;
  String? get completionStatus => enrollment.completionStatus;
  String? get grade => enrollment.grade;
  bool get isActive => enrollment.isActive;
  bool get isCompleted => enrollment.isCompleted;

  String get courseCode => course?.courseCode ?? '';
  String get title => course?.title ?? '';
  String get description => course?.description ?? '';
  int? get creditHours => course?.creditHours;

  /// المدرّس والشعبة خاصان بالطرح، لا بالمساق الدائم.
  String get instructorName => offering?.instructorName ?? '';
  String get section => offering?.section ?? '';

  String get semesterName => semester?.semesterName ?? '';

  /// نوع المتطلب من خطة الطالب، أو null إذا كان المساق خارج الخطة.
  String? get requirementType => curriculumEntry?.requirementType;

  /// هل تعذّر إيجاد مستند المساق الدائم؟ تعرضه الواجهة كاسم غير معروف.
  bool get hasCourse => course != null;
}

/// مساق من خطة الطالب مطروح فعلًا في الفصل الحالي ويمكنه دراسته الآن.
class StudentAvailableCourseView {
  const StudentAvailableCourseView({
    required this.offering,
    this.course,
    this.curriculumEntry,
  });

  final CourseOfferingModel offering;
  final CourseModel? course;
  final CurriculumCourseModel? curriculumEntry;

  String get offeringId => offering.id;
  String get courseId => offering.courseId;
  String get semesterId => offering.semesterId;
  String get instructorName => offering.instructorName;
  String get section => offering.section;

  String get courseCode => course?.courseCode ?? '';
  String get title => course?.title ?? '';
  int? get creditHours => course?.creditHours;

  String? get requirementType => curriculumEntry?.requirementType;
  int? get academicLevel => curriculumEntry?.academicLevel;

  /// النص الرسمي للمتطلب السابق للعرض فقط؛ المتطلبات غير مُطبَّقة.
  String? get prerequisiteText => curriculumEntry?.prerequisiteText;
}

/// صف واحد من خطة التخصص جاهز للعرض: إمّا مساق محدد أو خانة متطلب.
class StudentProgramEntryView {
  const StudentProgramEntryView({required this.entry, this.course});

  final CurriculumCourseModel entry;

  /// null دائمًا لصفوف الخانات، فهي ليست مساقات ولا تملك مستندًا.
  final CourseModel? course;

  bool get isSlot => entry.isSlotEntry;
  int get academicLevel => entry.academicLevel;
  int get sequence => entry.sequence;
  String get requirementType => entry.requirementType;
  String? get prerequisiteText => entry.prerequisiteText;

  String get courseCode => course?.courseCode ?? '';

  /// عنوان الصف: اسم المساق، أو نص الخانة كما ورد في الخطة الرسمية.
  String get title => isSlot ? (entry.slotLabel ?? '') : (course?.title ?? '');

  /// ساعات الصف: الخانات وحدها تخزّن ساعاتها، والمساقات ترثها من مستندها.
  int get creditHours =>
      isSlot ? (entry.creditHours ?? 0) : (course?.creditHours ?? 0);
}
