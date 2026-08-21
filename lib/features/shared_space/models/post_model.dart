// lib/features/shared_space/models/post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'post_attachment.dart';

/// حالة المنشور: 'active' يظهر للطلاب، 'archived' مخفي — نفس مبدأ
/// CourseFileModel.status، حذف منطقي لا فعلي.
class PostModel {
  const PostModel({
    required this.id,
    required this.courseId,
    required this.authorId,
    required this.authorName,
    this.authorRole = '',
    required this.content,
    this.attachment,
    required this.createdAt,
    this.commentsCount = 0,
    this.likesCount = 0,
    this.isLikedByMe = false,
    this.status = statusActive,
  });

  static const String statusActive = 'active';
  static const String statusArchived = 'archived';

  final String id;
  final String courseId;
  final String authorId;
  final String authorName;

  /// غير موثَّق بعد في المستندات الحالية — يُكتب فارغًا حتى تُضاف بيانات
  /// الدور الحقيقية إلى مستند المستخدم لاحقًا. لا نخترع قيمة عرض بديلة
  /// هنا؛ الشاشة تقرر كيف تتعامل مع الفراغ.
  final String authorRole;

  final String content;
  final PostAttachment? attachment;

  final DateTime createdAt;
  final int commentsCount;
  final int likesCount;

  /// مشتقّ من استعلام منفصل على posts/{id}/likes/{currentUserId}، وليس
  /// حقلًا في مستند المنشور نفسه — Firestore لا يخزّن "حالتي أنا" داخل
  /// مستند مشترك بين كل المستخدمين.
  final bool isLikedByMe;

  final String status;

  bool get isActive => status == statusActive;

  factory PostModel.fromFirestore(
      Map<String, dynamic> data,
      String id, {
        bool isLikedByMe = false,
      }) {
    final attachmentData = data['attachment'] as Map<String, dynamic>?;
    return PostModel(
      id: id,
      courseId: data['courseId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorRole: data['authorRole'] as String? ?? '',
      content: data['content'] as String? ?? '',
      attachment: attachmentData == null
          ? null
          : PostAttachment.fromMap(attachmentData),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      isLikedByMe: isLikedByMe,
      status: data['status'] as String? ?? statusActive,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'content': content,
      'attachment': attachment?.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'commentsCount': 0,
      'likesCount': 0,
      'status': statusActive,
    };
  }

  PostModel copyWith({
    int? commentsCount,
    int? likesCount,
    bool? isLikedByMe,
  }) {
    return PostModel(
      id: id,
      courseId: courseId,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      content: content,
      attachment: attachment,
      createdAt: createdAt,
      commentsCount: commentsCount ?? this.commentsCount,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      status: status,
    );
  }
}