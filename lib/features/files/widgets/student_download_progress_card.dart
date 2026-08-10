
// lib/features/files/widgets/student_download_progress_card.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/student_app_file.dart';
import 'student_file_type_icon.dart';

/// Card variant shown for a file that is currently downloading
/// (`file.isDownloading == true`), displaying live progress instead
/// of the usual download/offline badge.
class DownloadProgressCard extends StatelessWidget {
  const DownloadProgressCard({
    super.key,
    required this.file,
    this.onCancelTap,
  });

  final StudentAppFile file;
  final VoidCallback? onCancelTap;

  @override
  Widget build(BuildContext context) {
    final progress = file.downloadProgress ?? 0.0;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FileTypeIcon(type: file.type),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  file.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.small),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.download_rounded,
                      size: AppSizes.iconExtraSmall,
                      color: AppColors.primary,
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.extraSmall),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: AppSizes.progressBarHeight,
                    backgroundColor: AppColors.surfaceSecondary,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onCancelTap != null)
            IconButton(
              onPressed: onCancelTap,
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}