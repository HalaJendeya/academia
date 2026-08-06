// lib/features/courses/models/student_course.dart

/// Represents a single academic course (synced or mock).
class Course {
  final String id;
  final String code;
  final String title;
  final String instructorName;
  final double progress;
  final double? rating;
  final String status;
  final String? upcomingBadgeLabel;
  final bool isBadgeUrgent;
  final String? finalGrade;
  final String? completedDateLabel;
  final String? coverImageAsset;
  final String? nextSessionDayLabel;
  final String? nextSessionTopic;
  final String? nextSessionTimeRangeLabel;
  final String? nextSessionModeLabel;

  const Course({
    required this.id,
    required this.code,
    required this.title,
    required this.instructorName,
    required this.progress,
    required this.status,
    this.rating,
    this.upcomingBadgeLabel,
    this.isBadgeUrgent = false,
    this.finalGrade,
    this.completedDateLabel,
    this.coverImageAsset,
    this.nextSessionDayLabel,
    this.nextSessionTopic,
    this.nextSessionTimeRangeLabel,
    this.nextSessionModeLabel,
  });

  static const String statusActive = 'active';
  static const String statusArchived = 'archived';

  bool get isArchived => status == statusArchived;
  bool get hasNextSession => nextSessionTopic != null;

  factory Course.fromFirestore(String id, Map<String, dynamic> data) {
    return Course(
      id: id,
      code: data['code'] as String? ?? '',
      title: data['title'] as String? ?? '',
      instructorName: data['instructorName'] as String? ?? '',
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? statusActive,
      rating: (data['rating'] as num?)?.toDouble(),
      upcomingBadgeLabel: data['upcomingBadgeLabel'] as String?,
      isBadgeUrgent: data['isBadgeUrgent'] as bool? ?? false,
      finalGrade: data['finalGrade'] as String?,
      completedDateLabel: data['completedDateLabel'] as String?,
      coverImageAsset: data['coverImageAsset'] as String?,
      nextSessionDayLabel: data['nextSessionDayLabel'] as String?,
      nextSessionTopic: data['nextSessionTopic'] as String?,
      nextSessionTimeRangeLabel: data['nextSessionTimeRangeLabel'] as String?,
      nextSessionModeLabel: data['nextSessionModeLabel'] as String?,
    );
  }

  Map<String, dynamic> toEditableFirestore() {
    return {
      'code': code,
      'title': title,
      'instructorName': instructorName,
      'progress': progress,
      'status': status,
      'rating': rating,
      'upcomingBadgeLabel': upcomingBadgeLabel,
      'isBadgeUrgent': isBadgeUrgent,
      'finalGrade': finalGrade,
      'completedDateLabel': completedDateLabel,
      'coverImageAsset': coverImageAsset,
      'nextSessionDayLabel': nextSessionDayLabel,
      'nextSessionTopic': nextSessionTopic,
      'nextSessionTimeRangeLabel': nextSessionTimeRangeLabel,
      'nextSessionModeLabel': nextSessionModeLabel,
    };
  }

  Course copyWith({
    String? id,
    String? code,
    String? title,
    String? instructorName,
    double? progress,
    String? status,
    double? rating,
    String? upcomingBadgeLabel,
    bool? isBadgeUrgent,
    String? finalGrade,
    String? completedDateLabel,
    String? coverImageAsset,
    String? nextSessionDayLabel,
    String? nextSessionTopic,
    String? nextSessionTimeRangeLabel,
    String? nextSessionModeLabel,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      instructorName: instructorName ?? this.instructorName,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      upcomingBadgeLabel: upcomingBadgeLabel ?? this.upcomingBadgeLabel,
      isBadgeUrgent: isBadgeUrgent ?? this.isBadgeUrgent,
      finalGrade: finalGrade ?? this.finalGrade,
      completedDateLabel: completedDateLabel ?? this.completedDateLabel,
      coverImageAsset: coverImageAsset ?? this.coverImageAsset,
      nextSessionDayLabel: nextSessionDayLabel ?? this.nextSessionDayLabel,
      nextSessionTopic: nextSessionTopic ?? this.nextSessionTopic,
      nextSessionTimeRangeLabel:
      nextSessionTimeRangeLabel ?? this.nextSessionTimeRangeLabel,
      nextSessionModeLabel: nextSessionModeLabel ?? this.nextSessionModeLabel,
    );
  }
}