// lib/features/courses/widgets/course_card.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../models/course.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, this.onTap});

  final Course course;
  final VoidCallback? onTap;

  static const double _coverHeight = 140;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCover(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  course.title,
                  style: AppTextStyles.titleMedium,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.extraSmall),
                _buildInstructorRow(),
                const SizedBox(height: AppSpacing.medium),
                _buildProgressSection(),
                const SizedBox(height: AppSpacing.medium),
                _buildFooterRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppRadius.card),
        topRight: Radius.circular(AppRadius.card),
      ),
      child: SizedBox(
        height: _coverHeight,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: _buildCoverBackground()),
            if (course.rating != null)
              Positioned(top: 8, left: 8, child: _buildRatingBadge()),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverBackground() {
    final coverImageAsset = course.coverImageAsset;
    if (coverImageAsset != null) {
      return Image.asset(coverImageAsset, fit: BoxFit.cover);
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.primaryDark],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: AppSizes.iconExtraLarge,
          color: AppColors.surfaceWhite60,
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            course.rating!.toStringAsFixed(1),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.person_outline_rounded,
          size: AppSizes.iconExtraSmall,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(course.instructorName, style: AppTextStyles.bodyMedium),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.courseProgressLabel,
              style: AppTextStyles.bodySmall,
            ),
            Text(
              '${(course.progress * 100).round()}%',
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
            value: course.progress.clamp(0.0, 1.0),
            minHeight: AppSizes.progressBarHeight,
            backgroundColor: AppColors.surfaceSecondary,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            AppStrings.continueCourseAction,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
          ),
        ),
        if (course.upcomingBadgeLabel != null) _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    if (course.isBadgeUrgent) {
      return AppStatusBadge(
        label: course.upcomingBadgeLabel!,
        backgroundColor: AppColors.error.withValues(alpha: 0.1),
        foregroundColor: AppColors.error,
        icon: Icons.warning_amber_rounded,
      );
    }
    return AppStatusBadge(
      label: course.upcomingBadgeLabel!,
      backgroundColor: AppColors.surfaceSecondary,
      foregroundColor: AppColors.textSecondary,
      icon: Icons.assignment_outlined,
    );
  }
}
