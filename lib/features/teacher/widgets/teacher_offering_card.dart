import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../models/teacher_offering_view.dart';

/// بطاقة طرح واحد في واجهة المعلّم.
///
/// تعرض ما هو مخزَّن فقط: المساق والفصل والشعبة والحالة. لا عدد طلاب هنا —
/// معرفته تتطلب قراءة قائمة كل طرح على حدة، وعرض رقم قبل قراءته اختلاق.
class TeacherOfferingCard extends StatelessWidget {
  const TeacherOfferingCard({super.key, required this.view, this.onTap});

  final TeacherOfferingView view;
  final VoidCallback? onTap;

  /// لون الحالة، مشترك بين البطاقة وشاشة التفاصيل.
  static Color statusColor(bool isActive) =>
      isActive ? AppColors.secondary : AppColors.textMuted;

  static String statusLabel(bool isActive) =>
      isActive ? AppStrings.activeStatus : AppStrings.archivedStatus;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  view.displayTitle,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: statusLabel(view.isActive),
                backgroundColor: statusColor(
                  view.isActive,
                ).withValues(alpha: 0.08),
                foregroundColor: statusColor(view.isActive),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: 6,
            children: [
              if (view.semesterName.isNotEmpty)
                AppStatusBadge(
                  label: view.semesterName,
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                  icon: Icons.event_note_rounded,
                ),
              AppStatusBadge(
                label: '${AppStrings.offeringSectionLabel} ${view.section}',
                backgroundColor: AppColors.surfaceSecondary,
                foregroundColor: AppColors.textSecondary,
              ),
              if (view.creditHours != null)
                AppStatusBadge(
                  label:
                      '${view.creditHours} ${AppStrings.creditHoursShort}',
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
