// lib/features/courses/models/course_file.dart

class CourseFile {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final String type;
  final String sizeLabel;
  final String dateLabel;
  final bool isNew;

  const CourseFile({
    required this.id,
    required this.courseId,
    required this.title,
    required this.type,
    required this.sizeLabel,
    required this.dateLabel,
    this.description,
    this.isNew = false,
  });

  static const String typePdf = 'pdf';
  static const String typeDoc = 'doc';
  static const String typePpt = 'ppt';
  static const String typeOther = 'other';

  factory CourseFile.fromFirestore(String id, Map<String, dynamic> data) {
    return CourseFile(
      id: id,
      courseId: data['courseId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      type: data['type'] as String? ?? typeOther,
      sizeLabel: data['sizeLabel'] as String? ?? '',
      dateLabel: data['dateLabel'] as String? ?? '',
      isNew: data['isNew'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toEditableFirestore() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'type': type,
      'sizeLabel': sizeLabel,
      'dateLabel': dateLabel,
      'isNew': isNew,
    };
  }

  CourseFile copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    String? type,
    String? sizeLabel,
    String? dateLabel,
    bool? isNew,
  }) {
    return CourseFile(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      dateLabel: dateLabel ?? this.dateLabel,
      isNew: isNew ?? this.isNew,
    );
  }
}