// lib/features/courses/widgets/next_session_card.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/course.dart';

class NextSessionCard extends StatelessWidget {
  const NextSessionCard({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    if (!course.hasNextSession) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: AppSizes.iconSmall,
                color: AppColors.surfaceWhite60,
              ),
              const SizedBox(width: AppSpacing.extraSmall),
              if (course.nextSessionDayLabel != null) _buildDayBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            course.nextSessionTopic!,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (course.nextSessionModeLabel != null)
                _buildInfoChip(
                  icon: Icons.videocam_outlined,
                  label: course.nextSessionModeLabel!,
                ),
              if (course.nextSessionTimeRangeLabel != null)
                _buildInfoChip(
                  icon: Icons.access_time_rounded,
                  label: course.nextSessionTimeRangeLabel!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite20,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        course.nextSessionDayLabel!,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconExtraSmall, color: AppColors.surfaceWhite60),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.surfaceWhite60,
          ),
        ),
      ],
    );
  }
}