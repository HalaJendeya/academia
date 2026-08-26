import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';

/// ملخص الخطة الدراسية.
///
/// خانة التصميم الأصلية كانت "ملخص التقدّم"، لكن نسبة الإنجاز تتطلب تسجيلات
/// مكتملة، ولا توجد أي تسجيلات بعد. عرض نسبة الآن يعني رقمًا مختلقًا، لذلك
/// أُعيد تفسير البطاقة كملخص للخطة نفسها: أرقام حقيقية مشتقة من المنهج.
class PlanSummaryCard extends StatelessWidget {
  const PlanSummaryCard({
    super.key,
    required this.hasMajor,
    this.totalCreditHours,
    this.academicLevel,
    this.levelCreditHours,
  });

  final bool hasMajor;
  final int? totalCreditHours;
  final int? academicLevel;
  final int? levelCreditHours;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.dashboardPlanSummaryTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
            textAlign: TextAlign.right,
          ),
          const Divider(color: AppColors.divider),
          if (!hasMajor)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Text(
                AppStrings.dashboardPlanUnavailable,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _metric(
                      AppStrings.dashboardPlanTotalHours,
                      '${totalCreditHours ?? 0}',
                    ),
                  ),
                  _divider(),
                  Expanded(
                    child: _metric(
                      AppStrings.dashboardCurrentLevel,
                      academicLevel != null
                          ? '$academicLevel'
                          : AppStrings.dashboardLevelUnknown,
                    ),
                  ),
                  _divider(),
                  Expanded(
                    child: _metric(
                      AppStrings.dashboardLevelHours,
                      '${levelCreditHours ?? 0}',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 40, color: AppColors.divider);

  Widget _metric(String label, String value) {
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
