// lib/features/courses/widgets/student_file_list_item_card.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/course_file.dart';

class FileListItemCard extends StatelessWidget {
  const FileListItemCard({
    super.key,
    required this.file,
    this.onDownloadTap,
  });

  final CourseFile file;
  final VoidCallback? onDownloadTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
          IconButton(
            onPressed: onDownloadTap,
            icon: const Icon(
              Icons.download_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon() {
    final isPdf = file.type == CourseFile.typePdf;
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
            if (file.isNew) ...[_buildNewBadge(), const SizedBox(width: 6)],
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
          '${file.dateLabel} • ${file.sizeLabel}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
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