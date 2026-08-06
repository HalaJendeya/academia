// lib/features/courses/services/student_course_file_service.dart

import '../models/course_file.dart';

class CourseFileException implements Exception {
  final String message;
  const CourseFileException(this.message);

  @override
  String toString() => message;
}

class CourseFileService {
  CourseFileService();

  static const Duration _mockDelay = Duration(milliseconds: 400);

  Future<List<CourseFile>> getCourseFiles(String courseId) async {
    await Future.delayed(_mockDelay);
    return _mockFiles.where((file) => file.courseId == courseId).toList();
  }

  static final List<CourseFile> _mockFiles = [
    const CourseFile(
      id: 'file_intro_cs_lecture1',
      courseId: 'course_software_eng',
      title: 'مقدمة في علوم الحاسب - المحاضرة الأولى',
      description: 'شرائح تعريفية بمساق هندسة البرمجيات.',
      type: CourseFile.typePdf,
      sizeLabel: '2.4 MB',
      dateLabel: '12 أكتوبر 2023',
      isNew: false,
    ),
    const CourseFile(
      id: 'file_chapter2_summary',
      courseId: 'course_software_eng',
      title: 'ملخص الفصل الثاني - متطلبات النظام',
      description: 'ملخص مكتوب لأهم نقاط الفصل الثاني.',
      type: CourseFile.typeDoc,
      sizeLabel: '1.1 MB',
      dateLabel: '15 أكتوبر 2023',
      isNew: false,
    ),
    const CourseFile(
      id: 'file_week3_assignment',
      courseId: 'course_software_eng',
      title: 'واجب الأسبوع الثالث - برمجة كائنية',
      description: 'وصف تفصيلي لمتطلبات تسليم الواجب.',
      type: CourseFile.typePdf,
      sizeLabel: '3.5 MB',
      dateLabel: '20 أكتوبر 2023',
      isNew: true,
    ),
  ];
}