// lib/features/shared_space/models/post_attachment.dart

/// مرفق ملف داخل منشور — Map متداخل جوا مستند المنشور، مطابق تمامًا
/// للحقول الموثَّقة فعليًا بـ Firestore (fileExtension, fileName, fileUrl,
/// sizeLabel).
class PostAttachment {
  const PostAttachment({
    required this.fileName,
    required this.fileUrl,
    required this.sizeLabel,
    required this.fileExtension,
  });

  final String fileName;
  final String fileUrl;
  final String sizeLabel;
  final String fileExtension;

  factory PostAttachment.fromMap(Map<String, dynamic> data) {
    return PostAttachment(
      fileName: data['fileName'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
      sizeLabel: data['sizeLabel'] as String? ?? '',
      fileExtension: data['fileExtension'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'fileUrl': fileUrl,
      'sizeLabel': sizeLabel,
      'fileExtension': fileExtension,
    };
  }
}