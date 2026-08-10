// lib/features/files/widgets/student_file_info_card.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/student_app_file.dart';

/// Card shown on the File Preview screen, listing the file's
/// subject, size, and upload date.
class FileInfoCard extends StatelessWidget {
  const FileInfoCard({super.key, required this.file});

  final StudentAppFile file;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.fileInfoSectionTitle,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: AppSpacing.medium),
          _buildInfoRow(
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.primary,
            label: AppStrings.fileInfoSubjectLabel,
            value: file.subjectLabel,
          ),
          const SizedBox(height: AppSpacing.medium),
          _buildInfoRow(
            icon: Icons.folder_zip_rounded,
            iconColor: AppColors.primaryDark,
            label: AppStrings.fileInfoSizeLabel,
            value: file.sizeLabel,
          ),
          const SizedBox(height: AppSpacing.medium),
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.primary,
            label: AppStrings.fileInfoDateLabel,
            value: file.dateLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: AppSizes.iconLarge,
          height: AppSizes.iconLarge,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(icon, color: iconColor, size: AppSizes.iconSmall),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 2),
              Text(
                value,
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
    );
  }
}