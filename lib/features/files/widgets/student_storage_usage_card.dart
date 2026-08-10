
// lib/features/files/widgets/student_storage_usage_card.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/student_app_file.dart';

/// Card shown on the Offline Files screen, summarizing how many
/// files are downloaded and the total storage they use.
///
/// Total size is computed from each file's [StudentAppFile.sizeLabel]
/// (e.g. "2.4 MB", "842 KB") — a lightweight parse, not a real
/// device storage query, since files are Mock Data at this stage.
class StorageUsageCard extends StatelessWidget {
  const StorageUsageCard({super.key, required this.files});

  final List<StudentAppFile> files;

  @override
  Widget build(BuildContext context) {
    final totalLabel = _formatTotalSize(files);

    return AppCard(
      child: Row(
        children: [
          Container(
            width: AppSizes.iconLarge,
            height: AppSizes.iconLarge,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: const Icon(
              Icons.sd_storage_rounded,
              color: AppColors.primary,
              size: AppSizes.iconSmall,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppStrings.storageUsageTitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalLabel • ${files.length} ${AppStrings.storageUsageFilesSuffix}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTotalSize(List<StudentAppFile> files) {
    var totalKb = 0.0;

    for (final file in files) {
      totalKb += _parseSizeToKb(file.sizeLabel);
    }

    if (totalKb >= 1024) {
      return '${(totalKb / 1024).toStringAsFixed(1)} MB';
    }
    return '${totalKb.toStringAsFixed(0)} KB';
  }

  static double _parseSizeToKb(String sizeLabel) {
    final normalized = sizeLabel.trim().toUpperCase();
    final numericPart = double.tryParse(
      normalized.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (numericPart == null) return 0.0;

    if (normalized.contains('MB')) return numericPart * 1024;
    if (normalized.contains('KB')) return numericPart;
    return 0.0;
  }
}