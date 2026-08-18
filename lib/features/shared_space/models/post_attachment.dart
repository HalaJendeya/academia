// lib/features/shared_space/models/post_attachment.dart

/// مرفق ملف داخل منشور بساحة المشاركة.
///
/// نموذج عرض بسيط بمرحلة Mock — لا يحمل رابط تنزيل حقيقي بعد. عند الربط
/// بالبيانات الحقيقية لاحقًا سيُبنى من نفس نوع الملفات المستخدَم بميزة
/// ملفات المساق (امتداد، حجم، رابط Cloudinary)، حفاظًا على تناسق التصنيف
/// بين الميزتين.
class PostAttachment {
  const PostAttachment({
    required this.fileName,
    required this.sizeLabel,
    required this.fileExtension,
  });

  final String fileName;
  final String sizeLabel;

  /// امتداد الملف بحروف صغيرة (pdf, doc, ppt...)؛ يحدد لون وأيقونة
  /// المرفق بنفس منطق أيقونة ملفات المساق.
  final String fileExtension;
}