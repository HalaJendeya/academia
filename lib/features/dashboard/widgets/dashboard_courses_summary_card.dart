import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';

/// ملخص مساقات الطالب: المسجَّل حاليًا والمتاح للتسجيل.
///
/// العددان مشتقان من المزوّد لا مكتوبان يدويًا، والصفر حالة مشروعة تُشرح
/// بنص واضح: طالب بلا تسجيلات ليس شاشة معطوبة.
class DashboardCoursesSummaryCard extends StatelessWidget {
  const DashboardCoursesSummaryCard({
    super.key,
    required this.currentCount,
    required this.availableCount,
    required this.hasCurrentSemester,
    this.onOpenCourses,
  });

  final int currentCount;
  final int availableCount;
  final bool hasCurrentSemester;
  final VoidCallback? onOpenCourses;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.dashboardCoursesTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
            textAlign: TextAlign.right,
          ),
          const Divider(color: AppColors.divider),
          if (!hasCurrentSemester)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Text(
                AppStrings.noCurrentSemesterDesc,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _metric(
                      '$currentCount',
                      AppStrings.dashboardCurrentCoursesLabel,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.divider),
                  Expanded(
                    child: _metric(
                      '$availableCount',
                      AppStrings.dashboardAvailableNowLabel,
                    ),
                  ),
                ],
              ),
            ),
            if (currentCount == 0) _note(AppStrings.dashboardNoCurrentCourses),
            if (availableCount == 0)
              _note(AppStrings.dashboardNoAvailableCourses),
          ],
          if (onOpenCourses != null) ...[
            const SizedBox(height: AppSpacing.small),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onOpenCourses,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text(AppStrings.dashboardOpenCoursesAction),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _note(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.small),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
