import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../models/student_course_view.dart';

/// محاولة سابقة واحدة في السجل الدراسي.
///
/// مبنية على بطاقة الأرشيف التي صمّمها فريق الواجهة (مصغّرة على اليمين،
/// عنوان، سطر الرمز والتاريخ، شارة النتيجة)، مع حذف زر "إعادة تنشيط":
/// الطالب لا يملك تغيير حالة تسجيله، والتسجيل يتم عبر المشرف.
class StudentAttemptCard extends StatelessWidget {
  const StudentAttemptCard({super.key, required this.view, this.onTap});

  final StudentCourseView view;
  final VoidCallback? onTap;

  static const double _thumbnailSize = 64;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(),
          const SizedBox(width: AppSpacing.medium),
          Expanded(child: _buildInfo()),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Container(
        width: _thumbnailSize,
        height: _thumbnailSize,
        color: AppColors.surfaceSecondary,
        child: const Icon(
          Icons.menu_book_rounded,
          color: AppColors.textMuted,
          size: AppSizes.iconMedium,
        ),
      ),
    );
  }

  Widget _buildInfo() {
    final subtitleParts = <String>[
      if (view.courseCode.isNotEmpty) view.courseCode,
      if (view.semesterName.isNotEmpty) view.semesterName,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          view.hasCourse ? view.title : AppStrings.unknownCourse,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitleParts.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitleParts.join(' • '),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.right,
          ),
        ],
        if (view.instructorName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            view.instructorName,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: AppSpacing.small),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppStatusBadge(
              label: '${AppStrings.attemptLabel} ${view.attemptNumber}',
              backgroundColor: AppColors.surfaceSecondary,
              foregroundColor: AppColors.textSecondary,
            ),
            if (view.completionStatus != null) _buildCompletionBadge(),
            if (view.grade != null && view.grade!.trim().isNotEmpty)
              AppStatusBadge(
                label: '${AppStrings.gradeLabel}: ${view.grade}',
                backgroundColor: AppColors.surfaceSecondary,
                foregroundColor: AppColors.textSecondary,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionBadge() {
    final passed = view.completionStatus == EnrollmentModel.completionPassed;
    final failed = view.completionStatus == EnrollmentModel.completionFailed;

    final color = passed
        ? AppColors.secondary
        : failed
        ? AppColors.danger
        : AppColors.textSecondary;

    return AppStatusBadge(
      label: AppStrings.completionStatusDisplay(view.completionStatus),
      backgroundColor: color.withValues(alpha: 0.08),
      foregroundColor: color,
      icon: passed ? Icons.check_circle_rounded : null,
    );
  }
}
