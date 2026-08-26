import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../models/student_course_view.dart';

/// مساق من خطة الطالب مطروح في الفصل الحالي.
///
/// بطاقة مدمجة بلا غلاف: القائمة هنا تُقرأ للمقارنة بين خيارات الفصل، لا
/// للتصفح، فالكثافة أنفع من الصور.
class StudentAvailableCourseCard extends StatelessWidget {
  const StudentAvailableCourseCard({
    super.key,
    required this.view,
    this.onTap,
  });

  final StudentAvailableCourseView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  view.title.isEmpty ? AppStrings.unknownCourse : view.title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              if (view.creditHours != null)
                Text(
                  '${view.creditHours} ${AppStrings.creditHoursSuffix}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (view.courseCode.isNotEmpty) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                view.courseCode,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.small),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: AppSizes.iconExtraSmall,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  view.instructorName,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              if (view.section.isNotEmpty)
                AppStatusBadge(
                  label: '${AppStrings.sectionLabel} ${view.section}',
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                ),
              if (view.requirementType != null)
                AppStatusBadge(
                  label: AppStrings.requirementTypeDisplay(
                    view.requirementType!,
                  ),
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
                  foregroundColor: AppColors.secondary,
                ),
              if (view.academicLevel != null)
                AppStatusBadge(
                  label: AppStrings.academicLevelDisplay(view.academicLevel!),
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                ),
            ],
          ),
          if (view.prerequisiteText != null &&
              view.prerequisiteText!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${AppStrings.prerequisiteLabel}: ${view.prerequisiteText}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }
}
