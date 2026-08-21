// lib/features/shared_space/widgets/post_attachment_preview.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/post_attachment.dart';

const List<String> _imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

/// معاينة مرفق موحَّدة، تُستخدَم ببطاقة القائمة وشاشة التفاصيل معًا.
///
/// الفتح ذكي حسب النوع، ومُدار داخليًا هنا (لا حاجة لتمرير onTap من كل
/// شاشة تستخدمها، ولا لتكرار نفس القرار مرتين):
/// - صورة: عارض كامل الشاشة داخل التطبيق نفسه (InteractiveViewer قابل
///   للتكبير)، لا متصفح خارجي — الصورة سياق بصري سريع، لا ملفًا يُحمَّل.
/// - أي نوع آخر (PDF أساسًا): متصفح خارجي عبر url_launcher، كما كان.
class PostAttachmentPreview extends StatelessWidget {
  const PostAttachmentPreview({super.key, required this.attachment});

  final PostAttachment attachment;

  bool get _isImage =>
      _imageExtensions.contains(attachment.fileExtension.toLowerCase());

  Future<void> _handleTap(BuildContext context) async {
    if (attachment.fileUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط الملف غير صالح')),
      );
      return;
    }

    if (_isImage) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _FullScreenImageViewer(
            imageUrl: attachment.fileUrl,
            title: attachment.fileName,
          ),
          fullscreenDialog: true,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(attachment.fileUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط الملف غير صالح')),
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الملف')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
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

/// عارض صورة كامل الشاشة، داخل التطبيق نفسه — لا يفتح متصفحًا خارجيًا.
/// InteractiveViewer يسمح بالتكبير/التصغير باللمس، كأي عارض صور عادي.
class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({required this.imageUrl, required this.title});

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}