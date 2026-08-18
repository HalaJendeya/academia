import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../models/course_assignment_model.dart';
import 'assignment_status_chips.dart';

/// بطاقة واجب مضغوطة لقوائم المعلّم والمشرف.
///
/// [contextLabel] هو المساق/الشعبة، ويُمرَّر من الأعلى لأن الواجب يحمل
/// معرّفات لا أسماء: حلّ الاسم مسؤولية الشاشة التي تملك مزوّد المساقات.
/// null يعني «لم يُحلّ بعد» فلا يُعرض سطر فارغ.
class AssignmentListCard extends StatelessWidget {
  const AssignmentListCard({
    super.key,
    required this.assignment,
    this.contextLabel,
    this.trailing,
    this.onTap,
    this.relativeTo,
  });

  final CourseAssignmentModel assignment;
  final String? contextLabel;
  final Widget? trailing;
  final VoidCallback? onTap;
  final DateTime? relativeTo;

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
                  assignment.title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.small),
                trailing!,
              ],
            ],
          ),
          if (contextLabel != null && contextLabel!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              contextLabel!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.small),
          // Wrap لا Row: أربع شارات لا تتسع في صف واحد على عرض 360.
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusBadge(
                label: assignment.dueDateLabel,
                backgroundColor: AppColors.surfaceSecondary,
                foregroundColor: AppColors.textSecondary,
                icon: Icons.event_rounded,
              ),
              AssignmentPriorityBadge(priority: assignment.priority),
              AssignmentDueStateBadge(
                assignment: assignment,
                relativeTo: relativeTo,
              ),
              if (assignment.isArchived)
                const AppStatusBadge(
                  label: AppStrings.archivedStatus,
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textMuted,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
