import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String courseCode;
  final String title;
  final String description;
  final String instructorName;
  final String department;
  final int semester;
  final String academicYear;
  final int creditHours;
  final String status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourseModel({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.description,
    required this.instructorName,
    required this.department,
    required this.semester,
    required this.academicYear,
    required this.creditHours,
    required this.status,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isArchived => status == 'archived';

  factory CourseModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return CourseModel(
      id: id,
      courseCode: data['courseCode'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      instructorName: data['instructorName'] as String? ?? '',
      department: data['department'] as String? ?? '',
      semester: (data['semester'] as num?)?.toInt() ?? 1,
      academicYear: data['academicYear'] as String? ?? '',
      creditHours: (data['creditHours'] as num?)?.toInt() ?? 3,
      status: data['status'] as String? ?? 'active',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseCode': courseCode,
      'title': title,
      'description': description,
      'instructorName': instructorName,
      'department': department,
      'semester': semester,
      'academicYear': academicYear,
      'creditHours': creditHours,
      'status': status,
      'createdBy': createdBy,
    };
  }

  CourseModel copyWith({
    String? id,
    String? courseCode,
    String? title,
    String? description,
    String? instructorName,
    String? department,
    int? semester,
    String? academicYear,
    int? creditHours,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      description: description ?? this.description,
      instructorName: instructorName ?? this.instructorName,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      creditHours: creditHours ?? this.creditHours,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
