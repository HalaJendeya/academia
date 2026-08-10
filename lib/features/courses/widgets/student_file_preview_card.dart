// lib/features/courses/widgets/student_file_preview_card.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../models/student_course_file.dart';

/// Card previewing a single course file, shown on the Course Detail
/// "Overview" tab.
///
/// Visually distinct from [FileListItemCard] (used in the "Files"
/// tab's row-style list) — this variant matches the Figma design's
/// larger card with a "new" badge, description, and a full-width
/// download action, mirroring [AssignmentPreviewCard]'s layout.
class FilePreviewCard extends StatelessWidget {
  const FilePreviewCard({
    super.key,
    required this.file,
    this.onDownloadTap,
  });

  final CourseFile file;
  final VoidCallback? onDownloadTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTypeIcon(),
              if (file.isNew) _buildNewBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            file.title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
          if (file.description != null) ...[
            const SizedBox(height: AppSpacing.extraSmall),
            Text(
              file.description!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ],
          const SizedBox(height: AppSpacing.medium),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDownloadTap,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text(AppStrings.fileDownloadAction),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border, width: 1),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.small,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
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

  Widget _buildNewBadge() {
    return AppStatusBadge(
      label: AppStrings.newFileBadgeLabel,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      foregroundColor: AppColors.primary,
    );
  }
}