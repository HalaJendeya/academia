// lib/features/courses/models/course_assignment_preview.dart

class CourseAssignmentPreview {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final String dueDateLabel;
  final bool isUrgent;

  const CourseAssignmentPreview({
    required this.id,
    required this.courseId,
    required this.title,
    required this.dueDateLabel,
    this.description,
    this.isUrgent = false,
  });

  factory CourseAssignmentPreview.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return CourseAssignmentPreview(
      id: id,
      courseId: data['courseId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      dueDateLabel: data['dueDateLabel'] as String? ?? '',
      isUrgent: data['isUrgent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toEditableFirestore() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'dueDateLabel': dueDateLabel,
      'isUrgent': isUrgent,
    };
  }

  CourseAssignmentPreview copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    String? dueDateLabel,
    bool? isUrgent,
  }) {
    return CourseAssignmentPreview(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDateLabel: dueDateLabel ?? this.dueDateLabel,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
}