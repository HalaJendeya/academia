// lib/features/shared_space/models/comment_model.dart

/// تعليق واحد على منشور بساحة المشاركة.
///
/// [postId] موجود عمدًا حتى بمرحلة الـ Mock — نفس مبدأ courseId في
/// PostModel: الاستعلام الحقيقي لاحقًا سيكون "تعليقات منشور واحد"، فلا
/// معنى لنموذج بلا ربط بمنشوره.
class CommentModel {
  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;
}