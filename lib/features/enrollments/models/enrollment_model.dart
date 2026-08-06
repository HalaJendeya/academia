import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String id;
  final String userId;
  final String courseId;
  final String status;
  final String assignedBy;
  final DateTime? assignedAt;
  final DateTime? updatedAt;

  const EnrollmentModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.status,
    required this.assignedBy,
    this.assignedAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isRemoved => status == 'removed';

  factory EnrollmentModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return EnrollmentModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      assignedBy: data['assignedBy'] as String? ?? '',
      assignedAt: parseDateTime(data['assignedAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'status': status,
      'assignedBy': assignedBy,
    };
  }

  EnrollmentModel copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? status,
    String? assignedBy,
    DateTime? assignedAt,
    DateTime? updatedAt,
  }) {
    return EnrollmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      status: status ?? this.status,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
