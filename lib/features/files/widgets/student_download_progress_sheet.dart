// lib/features/files/widgets/student_download_progress_sheet.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/student_app_file.dart';
import 'student_file_type_icon.dart';

/// Modal bottom sheet showing an in-progress file download, with a
/// live-looking progress bar, size, and remaining time.
///
/// Mock Data only at this stage — [downloadProgress], [downloadedSizeLabel],
/// [totalSizeLabel], and [remainingTimeLabel] are passed in as fixed
/// values rather than driven by a real download stream.
class DownloadProgressSheet extends StatelessWidget {
  const DownloadProgressSheet({
    super.key,
    required this.file,
    required this.downloadProgress,
    required this.downloadedSizeLabel,
    required this.totalSizeLabel,
    required this.remainingTimeLabel,
    this.onCancelTap,
  });

  final StudentAppFile file;
  final double downloadProgress;
  final String downloadedSizeLabel;
  final String totalSizeLabel;
  final String remainingTimeLabel;
  final VoidCallback? onCancelTap;

  static Future<void> show(
      BuildContext context, {
        required StudentAppFile file,
        required double downloadProgress,
        required String downloadedSizeLabel,
        required String totalSizeLabel,
        required String remainingTimeLabel,
        VoidCallback? onCancelTap,
      }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (context) => DownloadProgressSheet(
        file: file,
        downloadProgress: downloadProgress,
        downloadedSizeLabel: downloadedSizeLabel,
        totalSizeLabel: totalSizeLabel,
        remainingTimeLabel: remainingTimeLabel,
        onCancelTap: onCancelTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.small,
        AppSpacing.screenHorizontal,
        AppSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          Text(
            AppStrings.downloadProgressSheetTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                file.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              FileTypeIcon(type: file.type, size: 28),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$downloadedSizeLabel / $totalSizeLabel',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                '${(downloadProgress * 100).round()}% ${AppStrings.downloadProgressCompleteLabel}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: downloadProgress.clamp(0.0, 1.0),
              minHeight: AppSizes.progressBarHeight,
              backgroundColor: AppColors.surfaceSecondary,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            remainingTimeLabel,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.large),
          OutlinedButton(
            onPressed: onCancelTap ?? () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.border, width: 1),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: const Text(AppStrings.cancelDownloadAction),
          ),
        ],
      ),
    );
  }
}