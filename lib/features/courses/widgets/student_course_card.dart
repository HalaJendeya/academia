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

/// بطاقة مساق مسجَّل في الفصل الحالي.
///
/// مبنية على تصميم بطاقة فريق الواجهة (غلاف متدرّج، عنوان، سطر المدرّس،
/// إجراء في الأسفل)، مع حذف شريط نسبة الإنجاز والتقييم وشارة المهام
/// القادمة: لا توجد مجموعة تُنتج تلك القيم، وعرضها يعني اختلاقها.
class StudentCourseCard extends StatelessWidget {
  const StudentCourseCard({super.key, required this.view, this.onTap});

  final StudentCourseView view;
  final VoidCallback? onTap;

  static const double _coverHeight = 110;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCover(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  view.hasCourse ? view.title : AppStrings.unknownCourse,
                  style: AppTextStyles.titleMedium,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.extraSmall),
                if (view.instructorName.isNotEmpty) _buildInstructorRow(),
                const SizedBox(height: AppSpacing.small),
                _buildMetaRow(),
                const SizedBox(height: AppSpacing.medium),
                _buildFooterRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppRadius.card),
        topRight: Radius.circular(AppRadius.card),
      ),
      child: SizedBox(
        height: _coverHeight,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.secondary, AppColors.primaryDark],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: AppSizes.iconExtraLarge,
                    color: AppColors.surfaceWhite60,
                  ),
                ),
              ),
            ),
            if (view.courseCode.isNotEmpty)
              Positioned(top: 8, left: 8, child: _buildCodeBadge()),
            // إعادة الدراسة معلومة أكاديمية حقيقية، بخلاف الشارات الوهمية.
            if (view.isRetake)
              Positioned(top: 8, right: 8, child: _buildAttemptBadge()),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        view.courseCode,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.bold,
        ),
        textDirection: TextDirection.ltr,
      ),
    );
  }

  Widget _buildAttemptBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        '${AppStrings.attemptLabel} ${view.attemptNumber}',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInstructorRow() {
    return Row(
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
    );
  }

  Widget _buildMetaRow() {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (view.semesterName.isNotEmpty)
          AppStatusBadge(
            label: view.semesterName,
            backgroundColor: AppColors.surfaceSecondary,
            foregroundColor: AppColors.textSecondary,
            icon: Icons.event_note_rounded,
          ),
        if (view.section.isNotEmpty)
          AppStatusBadge(
            label: '${AppStrings.sectionLabel} ${view.section}',
            backgroundColor: AppColors.surfaceSecondary,
            foregroundColor: AppColors.textSecondary,
          ),
        if (view.creditHours != null)
          AppStatusBadge(
            label: '${view.creditHours} ${AppStrings.creditHoursSuffix}',
            backgroundColor: AppColors.surfaceSecondary,
            foregroundColor: AppColors.textSecondary,
          ),
        if (view.requirementType == null)
          AppStatusBadge(
            label: AppStrings.courseNotInProgramNote,
            backgroundColor: AppColors.warning.withValues(alpha: 0.12),
            foregroundColor: AppColors.warningDark,
          ),
      ],
    );
  }

  Widget _buildFooterRow() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          AppStrings.viewDetailsAction,
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
