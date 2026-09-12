// lib/features/notifications/models/app_notification.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// إشعار داخل التطبيق (In-App) — لا Push، لا يوقظ الجهاز إن كان التطبيق
/// مغلقًا. مجموعة notifications جذرية بحقل recipientId، بنفس مبدأ
/// postReports مع reporterId: كل إشعار مستقل، لا Sub-collection متداخلة،
/// فالاستعلام "إشعاراتي أنا" بسيط (where recipientId == uid).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.courseId,
    this.postId,
    this.assignmentId,
    required this.createdAt,
    this.isRead = false,
  });

  /// أنواع الإشعار المعروفة حاليًا — نوع واحد بس بهذه المرحلة
  /// (newSharedSpacePost)، والحقل موجود عمدًا لإضافة أنواع لاحقًا (واجب
  /// جديد، رد على تعليقي...) دون تغيير شكل النموذج أو الشاشة.
  static const String typeNewSharedSpacePost = 'newSharedSpacePost';

  /// واجب أكاديمي جديد على شُعبة الطالب.
  static const String typeNewAssignment = 'newAssignment';

  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String body;

  /// معرّفا السياق — يُستخدمان للانتقال المباشر عند الضغط على الإشعار
  /// (فتح المنشور نفسه)، لا للعرض.
  final String? courseId;
  final String? postId;

  /// معرّف الواجب لإشعارات typeNewAssignment — اختياري، فالإشعارات
  /// القديمة لا تحمله ويجب أن تبقى مقروءة كما هي.
  final String? assignmentId;

  final DateTime createdAt;
  final bool isRead;

  factory AppNotification.fromFirestore(Map<String, dynamic> data, String id) {
    return AppNotification(
      id: id,
      recipientId: data['recipientId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      courseId: data['courseId'] as String?,
      postId: data['postId'] as String?,
      assignmentId: data['assignmentId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'body': body,
      'courseId': courseId,
      'postId': postId,
      'assignmentId': assignmentId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    };
  }
}