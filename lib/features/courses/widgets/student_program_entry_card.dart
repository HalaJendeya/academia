import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../models/student_course_view.dart';

/// صف واحد من الخطة الدراسية.
///
/// الصف إمّا مساق محدد أو خانة متطلب. الخانة ليست مساقًا ولا مستند لها،
/// لذلك لا تُفتح لها تفاصيل ولا تستقبل onTap إطلاقًا.
class StudentProgramEntryCard extends StatelessWidget {
  const StudentProgramEntryCard({super.key, required this.entry, this.onTap});

  final StudentProgramEntryView entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSlot = entry.isSlot;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      onTap: isSlot ? null : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSlot
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                '${entry.creditHours} ${AppStrings.creditHoursSuffix}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: 6,
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
              AppStatusBadge(
                label: AppStrings.requirementTypeDisplay(entry.requirementType),
                backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
                foregroundColor: AppColors.secondary,
              ),
              if (isSlot)
                AppStatusBadge(
                  label: AppStrings.slotEntryBadge,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                  foregroundColor: AppColors.warningDark,
                ),
            ],
          ),
          if (isSlot) ...[
            const SizedBox(height: 6),
            Text(
              AppStrings.slotNotACourseNote,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.right,
            ),
          ],
          if (entry.prerequisiteText != null &&
              entry.prerequisiteText!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.link_rounded,
                  size: AppSizes.iconExtraSmall,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${AppStrings.prerequisiteLabel}: ${entry.prerequisiteText}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// عنوان مستوى داخل الخطة، مع مجموع ساعاته.
class StudentProgramLevelHeader extends StatelessWidget {
  const StudentProgramLevelHeader({
    super.key,
    required this.level,
    required this.creditHours,
  });

  final int level;
  final int creditHours;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.medium,
        bottom: AppSpacing.small,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            AppStrings.academicLevelDisplay(level),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const Spacer(),
          Text(
            '$creditHours ${AppStrings.programLevelHoursSuffix}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
