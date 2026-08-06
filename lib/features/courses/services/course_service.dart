// lib/features/courses/services/course_service.dart

import '../models/course.dart';
import '../models/course_assignment_preview.dart';

class CourseException implements Exception {
  final String message;
  const CourseException(this.message);

  @override
  String toString() => message;
}

class CourseService {
  CourseService();

  static const Duration _mockDelay = Duration(milliseconds: 400);

  Future<List<Course>> getActiveCourses() async {
    await Future.delayed(_mockDelay);
    return _mockCourses.where((course) => !course.isArchived).toList();
  }

  Future<List<Course>> getArchivedCourses() async {
    await Future.delayed(_mockDelay);
    return _mockCourses.where((course) => course.isArchived).toList();
  }

  Future<Course> getCourseById(String id) async {
    await Future.delayed(_mockDelay);
    try {
      return _mockCourses.firstWhere((course) => course.id == id);
    } catch (_) {
      throw const CourseException('لم يتم العثور على المقرر المطلوب.');
    }
  }

  Future<List<CourseAssignmentPreview>> getCourseAssignments(
      String courseId,
      ) async {
    await Future.delayed(_mockDelay);
    return _mockAssignments
        .where((assignment) => assignment.courseId == courseId)
        .toList();
  }

  static final List<Course> _mockCourses = [
    const Course(
      id: 'course_intro_cs',
      code: 'CS101',
      title: 'مقدمة في علوم الحاسب',
      instructorName: 'د. محمد العتيبي',
      progress: 0.65,
      status: Course.statusActive,
      rating: 4.8,
      upcomingBadgeLabel: '4 مهام قادمة',
      isBadgeUrgent: false,
    ),
    const Course(
      id: 'course_discrete_math',
      code: 'MATH201',
      title: 'رياضيات منفصلة',
      instructorName: 'أ.د. خالد السعيد',
      progress: 0.30,
      status: Course.statusActive,
      rating: 4.5,
      upcomingBadgeLabel: 'اختبار غدًا',
      isBadgeUrgent: true,
    ),
    const Course(
      id: 'course_ui_ux',
      code: 'DES210',
      title: 'تصميم واجهات المستخدم',
      instructorName: 'م. سارة الدوسري',
      progress: 0.85,
      status: Course.statusActive,
      rating: null,
      upcomingBadgeLabel: 'لا توجد مهام',
      isBadgeUrgent: false,
    ),
    const Course(
      id: 'course_software_eng',
      code: 'CS401',
      title: 'هندسة البرمجيات',
      instructorName: 'د. خالد عبدالرحمن',
      progress: 0.45,
      status: Course.statusActive,
      rating: null,
      nextSessionDayLabel: 'اليوم',
      nextSessionTopic: 'مراجعة الفصل الثالث: أنماط التصميم (Design Patterns)',
      nextSessionTimeRangeLabel: '10:00 ص - 11:30 ص',
      nextSessionModeLabel: 'عبر Zoom',
    ),
    const Course(
      id: 'course_cs101_archived',
      code: 'CS101',
      title: 'مقدمة في علم الحاسوب',
      instructorName: 'د. محمد العتيبي',
      progress: 1.0,
      status: Course.statusArchived,
      finalGrade: 'مكتمل 100% (A+)',
      completedDateLabel: 'أُنجز في 12 مايو 2023',
    ),
    const Course(
      id: 'course_math101_archived',
      code: 'MATH101',
      title: 'التفاضل والتكامل 1',
      instructorName: 'أ.د. خالد السعيد',
      progress: 1.0,
      status: Course.statusArchived,
      finalGrade: 'مكتمل 100% (A)',
      completedDateLabel: 'أُنجز في 20 يناير 2023',
    ),
    const Course(
      id: 'course_phys101_archived',
      code: 'PHYS101',
      title: 'الفيزياء العامة',
      instructorName: 'د. سارة المطيري',
      progress: 1.0,
      status: Course.statusArchived,
      finalGrade: 'مكتمل 100% (+B)',
      completedDateLabel: 'أُنجز في 15 ديسمبر 2022',
    ),
  ];

  static final List<CourseAssignmentPreview> _mockAssignments = [
    const CourseAssignmentPreview(
      id: 'assignment_se_project1',
      courseId: 'course_software_eng',
      title: 'تسليم المشروع الأول',
      description: 'رفع ملف التوثيق المبدئي للمشروع.',
      dueDateLabel: 'مستحق غدًا',
      isUrgent: true,
    ),
    const CourseAssignmentPreview(
      id: 'assignment_cs101_quiz1',
      courseId: 'course_intro_cs',
      title: 'اختبار قصير - الوحدة الثانية',
      description: 'يغطي محتوى محاضرات الأسبوعين الثالث والرابع.',
      dueDateLabel: 'مستحق خلال 3 أيام',
      isUrgent: false,
    ),
  ];
}