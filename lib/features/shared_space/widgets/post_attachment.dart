// lib/features/shared_space/widgets/post_attachment_preview.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/post_attachment.dart';

const List<String> _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

/// معاينة مرفق موحَّدة، تُستخدَم ببطاقة القائمة وشاشة التفاصيل معًا — بدل
/// نسخ نفس منطق الأيقونة/الحجم مرتين. الصور تُعرض كصورة مصغَّرة حقيقية
/// (Image.network على رابط Cloudinary الفعلي)، لا أيقونة عامة؛ باقي
/// الصيغ بأيقونة ولون حسب الامتداد، بنفس نظام الألوان المستخدَم بأيقونة
/// ملفات المساق (PDF/PPT بلون تحذيري، DOC وغيره بلون ثانوي).
class PostAttachmentPreview extends StatelessWidget {
  const PostAttachmentPreview({
    super.key,
    required this.attachment,
    this.onTap,
  });

  final PostAttachment attachment;
  final VoidCallback? onTap;

  bool get _isImage =>
      _imageExtensions.contains(attachment.fileExtension.toLowerCase());

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.small),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Row(
          children: [
            _buildThumbnail(),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    attachment.fileName,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    attachment.sizeLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (_isImage && attachment.fileUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: Image.network(
          attachment.fileUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          // فشل التحميل (رابط تالف، انقطاع شبكة) يسقط للأيقونة الاحتياطية
          // بدل مساحة مكسورة فارغة.
          errorBuilder: (context, error, stackTrace) => _buildIcon(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return _buildIcon();
  }

  Widget _buildIcon() {
    final config = _iconConfigFor(attachment.fileExtension.toLowerCase());
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Icon(config.icon, color: config.color, size: 22),
    );
  }

  _AttachmentIconConfig _iconConfigFor(String ext) {
    if (ext == 'pdf') {
      return const _AttachmentIconConfig(
        icon: Icons.picture_as_pdf_rounded,
        color: AppColors.warning,
      );
    }
    if (ext == 'ppt' || ext == 'pptx') {
      return const _AttachmentIconConfig(
        icon: Icons.slideshow_rounded,
        color: AppColors.warning,
      );
    }
    if (ext == 'doc' || ext == 'docx') {
      return const _AttachmentIconConfig(
        icon: Icons.description_rounded,
        color: AppColors.secondary,
      );
    }
    if (_imageExtensions.contains(ext)) {
      return const _AttachmentIconConfig(
        icon: Icons.image_rounded,
        color: AppColors.secondary,
      );
    }
    return const _AttachmentIconConfig(
      icon: Icons.insert_drive_file_rounded,
      color: AppColors.secondary,
    );
  }
}

class _AttachmentIconConfig {
  const _AttachmentIconConfig({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}
