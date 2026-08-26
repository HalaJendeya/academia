import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { high, medium, low }
enum TaskType { assignment, lecture, study, exam }
enum TaskStatus { pending, completed }

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? enrollmentId;
  final String? offeringId;
  final String? courseId;
  final DateTime? dueAt;
  final TaskPriority priority;
  final TaskStatus status;
  final TaskType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.enrollmentId,
    this.offeringId,
    this.courseId,
    this.dueAt,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.type = TaskType.study,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  bool get isCompleted => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isOverdue({DateTime? relativeTo}) {
    if (isCompleted || dueAt == null) return false;
    final now = relativeTo ?? DateTime.now();
    return dueAt!.isBefore(now) && !isSameDay(dueAt!, now);
  }

  bool isToday({DateTime? relativeTo}) {
    if (isCompleted || dueAt == null) return false;
    final now = relativeTo ?? DateTime.now();
    return isSameDay(dueAt!, now);
  }

  bool isUpcoming({DateTime? relativeTo}) {
    if (isCompleted || dueAt == null) return false;
    final now = relativeTo ?? DateTime.now();
    return dueAt!.isAfter(now) && !isSameDay(dueAt!, now);
  }

  factory TaskModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final priorityStr = data['priority'] as String? ?? 'medium';
    final statusStr = data['status'] as String? ?? 'pending';
    final typeStr = data['type'] as String? ?? 'study';

    final priority = TaskPriority.values.firstWhere(
      (e) => e.name == priorityStr,
      orElse: () => TaskPriority.medium,
    );
    final status = TaskStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => TaskStatus.pending,
    );
    final type = TaskType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => TaskType.study,
    );

    return TaskModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      enrollmentId: data['enrollmentId'] as String?,
      offeringId: data['offeringId'] as String?,
      courseId: data['courseId'] as String?,
      dueAt: parseDateTime(data['dueAt']),
      priority: priority,
      status: status,
      type: type,
      createdAt: parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(data['updatedAt']) ?? DateTime.now(),
      completedAt: parseDateTime(data['completedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      if (enrollmentId != null) 'enrollmentId': enrollmentId,
      if (offeringId != null) 'offeringId': offeringId,
      if (courseId != null) 'courseId': courseId,
      if (dueAt != null) 'dueAt': Timestamp.fromDate(dueAt!),
      'priority': priority.name,
      'status': status.name,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    };
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? enrollmentId,
    String? offeringId,
    String? courseId,
    DateTime? dueAt,
    TaskPriority? priority,
    TaskStatus? status,
    TaskType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCourseLink = false,
    bool clearCompletedAt = false,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      enrollmentId: clearCourseLink ? null : (enrollmentId ?? this.enrollmentId),
      offeringId: clearCourseLink ? null : (offeringId ?? this.offeringId),
      courseId: clearCourseLink ? null : (courseId ?? this.courseId),
      dueAt: dueAt ?? this.dueAt,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}
