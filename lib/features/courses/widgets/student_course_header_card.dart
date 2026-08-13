import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/course_model.dart';

/// ترويسة شاشة تفاصيل المساق.
///
/// نفس تصميم فريق الواجهة (شارة الرمز، العنوان، سطر فرعي)، بلا شريط نسبة
/// الإنجاز: لا توجد بيانات تقدّم في هذه المعمارية.
class StudentCourseHeaderCard extends StatelessWidget {
  const StudentCourseHeaderCard({
    super.key,
    required this.course,
    this.instructorName,
  });

  final CourseModel course;

  /// اسم المدرّس يأتي من الطرح لا من المساق الدائم، لذلك يُمرَّر اختياريًا:
  /// لا يوجد مدرّس عند عرض مساق من الخطة دون تسجيل.
  final String? instructorName;

  @override
  Widget build(BuildContext context) {
    final instructor = instructorName;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerRight, child: _buildCodeBadge()),
          const SizedBox(height: AppSpacing.small),
          Text(
            course.title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
          if (instructor != null && instructor.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.extraSmall),
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
                    instructor,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.small),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${course.creditHours} ${AppStrings.creditHoursSuffix}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        course.courseCode,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.bold,
        ),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}
