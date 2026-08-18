// lib/features/courses/widgets/student_assignment_preview_card.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../assignments/models/course_assignment_model.dart';
import '../../assignments/widgets/assignment_status_chips.dart';

class AssignmentPreviewCard extends StatelessWidget {
  const AssignmentPreviewCard({
    super.key,
    required this.assignment,
    this.onViewDetailsTap,
  });

  final CourseAssignmentModel assignment;
  final VoidCallback? onViewDetailsTap;

  @override
  Widget build(BuildContext context) {
    /*
     * الحالة الزمنية تُحسب لحظة البناء من موعد التسليم، ولا تُقرأ من حقل
     * مخزَّن: واجب «قريب» أمس هو «متأخر» اليوم دون أن يكتب أحد شيئًا.
     *
     * المتأخر يسبق المستحق اليوم — واجب فات موعده صباحًا متأخر لا مستحق.
     */
    final dueState = AssignmentDueStateBadge.resolve(assignment);
    final urgent = dueState != null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (urgent)
                Icon(
                  Icons.error_outline_rounded,
                  size: AppSizes.iconSmall,
                  color: dueState.color,
                ),
              Flexible(
                child: AppStatusBadge(
                  label: assignment.dueDateLabel,
                  backgroundColor: urgent
                      ? dueState.color.withValues(alpha: 0.1)
                      : AppColors.surfaceSecondary,
                  foregroundColor: urgent
                      ? dueState.color
                      : AppColors.textSecondary,
                ),
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
          if (assignment.description.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.extraSmall),
            Text(
              assignment.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
              // معاينة لا نص كامل: التفاصيل مكانها شاشة الواجب.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.small),
          // Wrap لا Row: شارتان مع نص عربي طويل تفيضان على عرض 360.
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: 6,
            children: [
              AssignmentPriorityBadge(priority: assignment.priority),
              AssignmentDueStateBadge(assignment: assignment),
            ],
          ),
          /*
           * الزر يظهر فقط حين يوجد ما يفتحه.
           *
           * لا شاشة تفاصيل واجب للطالب في هذه المرحلة، وزرّ معطَّل دائمًا
           * يَعِد بوجهة غير موجودة. البطاقة تعرض كل ما لدى الطالب أصلًا.
           */
          if (onViewDetailsTap != null) ...[
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
        ],
      ),
    );
  }
}