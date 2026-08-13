import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../courses/models/student_course_view.dart';

/// خانة "التوصيات" في التصميم الأصلي.
///
/// لا يوجد محرّك توصيات ولا نموذج ذكاء اصطناعي، لذلك أُعيد تفسيرها كما هي
/// أكاديميًا: ما تنصّ عليه خطة الطالب في مستواه الحالي. مصدرها المنهج
/// الرسمي، فلا شيء مختلق فيها.
class LevelRecommendationCard extends StatelessWidget {
  const LevelRecommendationCard({
    super.key,
    required this.entries,
    this.maxPreview = 3,
    this.onEntryTap,
  });

  final List<StudentProgramEntryView> entries;
  final int maxPreview;

  /// يُستدعى للمساقات فقط؛ خانات المتطلبات ليست مساقات ولا تُفتح لها تفاصيل.
  final void Function(StudentProgramEntryView entry)? onEntryTap;

  @override
  Widget build(BuildContext context) {
    final preview = entries.take(maxPreview).toList();
    final remaining = entries.length - preview.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.dashboardRecommendedTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.dashboardRecommendedDesc,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.right,
          ),
          const Divider(color: AppColors.divider),
          if (preview.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Text(
                AppStrings.dashboardRecommendedEmpty,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            )
          else ...[
            for (final entry in preview) _buildRow(entry),
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.small),
                child: Text(
                  '${AppStrings.dashboardMoreItems}: $remaining',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(StudentProgramEntryView entry) {
    final isSlot = entry.isSlot;

    final row = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSlot ? Icons.radio_button_unchecked : Icons.menu_book_rounded,
            size: 16,
            color: isSlot ? AppColors.textMuted : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSlot
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!isSlot && entry.courseCode.isNotEmpty)
                      Text(
                        entry.courseCode,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    if (isSlot)
                      AppStatusBadge(
                        label: AppStrings.slotEntryBadge,
                        backgroundColor: AppColors.warning.withValues(
                          alpha: 0.12,
                        ),
                        foregroundColor: AppColors.warningDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            '${entry.creditHours} ${AppStrings.creditHoursSuffix}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    // خانة المتطلب ليست مساقًا: لا تُغلَّف بمستقبِل ضغط إطلاقًا.
    if (isSlot || onEntryTap == null) return row;

    return InkWell(onTap: () => onEntryTap!(entry), child: row);
  }
}
