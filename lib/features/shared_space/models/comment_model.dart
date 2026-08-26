// lib/features/shared_space/models/comment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// تعليق واحد، جوا Sub-collection posts/{postId}/comments — الحقول
/// مطابقة تمامًا لمستند حقيقي موثَّق (authorId, authorName, content,
/// createdAt)، بلا أي حقل مُخترَع.
class CommentModel {
  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final String id;

  /// غير مخزَّن داخل مستند التعليق نفسه (معروف ضمنيًا من مسار الـ
  /// Sub-collection)، لكنه يُحفظ هنا لتسهيل تمرير النموذج بمعزل عن مساره
  /// الكامل بالشجرة.
  final String postId;

  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  factory CommentModel.fromFirestore(
      Map<String, dynamic> data,
      String id,
      String postId,
      ) {
    return CommentModel(
      id: id,
      postId: postId,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}