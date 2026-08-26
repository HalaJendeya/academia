// lib/features/courses/widgets/student_file_list_item_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../files/models/course_file_model.dart';

/// صف ملف داخل تبويب ملفات المساق.
///
/// التصميم كما هو من عمل الواجهة؛ المصدر صار [CourseFileModel] الحقيقي.
/// زر التنزيل استُبدل بفتح الملف: التنزيل غير المتصل مؤجَّل، والفتح يعمل
/// فعلًا عبر رابط Cloudinary.
class FileListItemCard extends StatelessWidget {
  const FileListItemCard({super.key, required this.file, this.onTap, this.now});

  final CourseFileModel file;
  final VoidCallback? onTap;

  /// اللحظة المرجعية لشارة «جديد». تُحقن في الاختبارات.
  final DateTime? now;

  String get _dateLabel {
    final createdAt = file.createdAt;
    if (createdAt == null) return AppStrings.notProvidedValue;
    return DateFormat('yyyy/MM/dd', 'ar').format(createdAt);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      child: Row(
        children: [
          _buildTypeIcon(),
          const SizedBox(width: AppSpacing.medium),
          Expanded(child: _buildInfo()),
          const SizedBox(width: AppSpacing.small),
          const Icon(Icons.open_in_new_rounded, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildTypeIcon() {
    final isPdf = file.typeGroup == CourseFileModel.typePdf;
    final color = isPdf ? AppColors.error : AppColors.secondary;
    final icon = isPdf
        ? Icons.picture_as_pdf_rounded
        : Icons.description_rounded;

    return Container(
      width: AppSizes.iconExtraLarge,
      height: AppSizes.iconExtraLarge,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Icon(icon, color: color, size: AppSizes.iconMedium),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file.isRecent(now: now)) ...[
              _buildNewBadge(),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                file.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$_dateLabel • ${file.readableSize}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        AppStrings.newFileBadgeLabel,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
