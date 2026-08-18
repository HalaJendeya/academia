// lib/features/shared_space/models/post_model.dart

import 'post_attachment.dart';

/// منشور واحد بساحة مشاركة مساق محدد.
///
/// [courseId] موجود حتى بمرحلة الـ Mock عمدًا: الشاشة مقيَّدة بمساق واحد
/// (تبويب "المساحة" داخل تفاصيل المساق)، فلا معنى لنموذج بلا معرّف مساق —
/// نفس المبدأ المتّبع في CourseFileModel لتفادي كسر البنية لاحقًا عند
/// الانتقال من Mock إلى Firestore.
class PostModel {
  const PostModel({
    required this.id,
    required this.courseId,
    required this.authorName,
    required this.authorRole,
    this.authorAvatarUrl,
    required this.content,
    this.attachment,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByMe = false,
  });

  final String id;
  final String courseId;

  final String authorName;

  /// دور الكاتب كما يُعرض تحت اسمه، مثل "طالب - هندسة البرمجيات" أو
  /// "مشرف المستوى الرابع".
  final String authorRole;
  final String? authorAvatarUrl;

  final String content;
  final PostAttachment? attachment;

  final DateTime createdAt;

  final int likesCount;
  final int commentsCount;

  /// حالة إعجاب محلية بمرحلة الـ Mock — لا تُخزَّن لكل مستخدم بعد.
  final bool isLikedByMe;

  PostModel copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLikedByMe,
  }) {
    return PostModel(
      id: id,
      courseId: courseId,
      authorName: authorName,
      authorRole: authorRole,
      authorAvatarUrl: authorAvatarUrl,
      content: content,
      attachment: attachment,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}

