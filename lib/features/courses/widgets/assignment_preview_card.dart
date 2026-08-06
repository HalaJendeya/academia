// lib/features/courses/widgets/assignment_preview_card.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../models/course_assignment_preview.dart';

class AssignmentPreviewCard extends StatelessWidget {
  const AssignmentPreviewCard({
    super.key,
    required this.assignment,
    this.onViewDetailsTap,
  });

  final CourseAssignmentPreview assignment;
  final VoidCallback? onViewDetailsTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (assignment.isUrgent)
                const Icon(
                  Icons.error_outline_rounded,
                  size: AppSizes.iconSmall,
                  color: AppColors.error,
                ),
              AppStatusBadge(
                label: assignment.dueDateLabel,
                backgroundColor: assignment.isUrgent
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.surfaceSecondary,
                foregroundColor: assignment.isUrgent
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            assignment.title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
          if (assignment.description != null) ...[
            const SizedBox(height: AppSpacing.extraSmall),
            Text(
              assignment.description!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ],
          const SizedBox(height: AppSpacing.medium),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewDetailsTap,
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
              child: const Text(AppStrings.viewDetailsAction),
            ),
          ),
        ],
      ),
    );
  }
}