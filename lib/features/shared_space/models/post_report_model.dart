// lib/features/shared_space/models/post_report_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// بلاغ عن منشور، من مجموعة postReports الجذرية (لا Sub-collection —
/// البلاغات تُراجَع مركزيًا عبر كل المساقات، بخلاف comments وlikes
/// المرتبطة بمنشور واحد تحديدًا).
class PostReportModel {
  const PostReportModel({
    required this.id,
    required this.postId,
    required this.courseId,
    required this.reporterId,
    required this.reason,
    this.notes = '',
    this.status = statusPending,
    required this.createdAt,
  });

  static const String statusPending = 'pending';
  static const String statusResolved = 'resolved';

  final String id;
  final String postId;
  final String courseId;
  final String reporterId;
  final String reason;
  final String notes;
  final String status;
  final DateTime createdAt;

  factory PostReportModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PostReportModel(
      id: id,
      postId: data['postId'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      reporterId: data['reporterId'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      status: data['status'] as String? ?? statusPending,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// تسمية السبب بالعربية — نفس أسماء القيم المستخدَمة بـ ReportPostSheet،
  /// مصدر واحد للحقيقة بين شاشة الإرسال وشاشة المراجعة.
  String get reasonDisplay {
    switch (reason) {
      case 'inappropriate_content':
        return 'محتوى غير مناسب';
      case 'misleading_information':
        return 'معلومات مضللة';
      case 'abuse':
        return 'إساءة';
      case 'unrelated':
        return 'غير متعلق بالمساق';
      default:
        return reason;
    }
  }
}