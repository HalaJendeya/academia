import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../models/study_session_model.dart';

/// سطر جلسة واحدة في «آخر الجلسات».
///
/// كل ما يظهر هنا مخزَّن فعلًا: المساق والتاريخ والمدة الفعلية والحالة.
/// لا نسبة إنجاز ولا تقييم — لا يوجد ما يُحسب منه أيٌّ منهما.
class StudySessionCard extends StatelessWidget {
  const StudySessionCard({
    super.key,
    required this.session,
    this.courseTitle,
  });

  final StudySessionModel session;

  /// اسم المساق إن أمكن حلّه. الجلسة تخزّن المعرّف لا الاسم، وتعذّر الحلّ
  /// يعني عرض «مذاكرة عامة» بدل معرّف لا يقرأه أحد.
  final String? courseTitle;

  String get _title {
    final resolved = courseTitle?.trim();
    if (resolved != null && resolved.isNotEmpty) return resolved;
    return AppStrings.sessionGeneralStudy;
  }

  /// تاريخ ميلادي مختصر: يوم/شهر/سنة.
  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = session.isCancelled;

    return AppCard(
      child: Row(
        children: [
          Icon(
            isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
            color: isCancelled ? AppColors.textSecondary : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.itemSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: AppTextStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.extraSmall),
                Text(
                  formatDate(session.startedAt),
                  style: AppTextStyles.bodySmall,
                ),
                // المدة الفعلية للمكتملة وحدها: الملغاة لم تُحتسب، وعرض
                // "٠ دقيقة" لها يوحي بقياس لم يحدث.
                if (!isCancelled) ...[
                  const SizedBox(height: AppSpacing.extraSmall),
                  Text(
                    '${AppStrings.sessionActualDurationPrefix} '
                    '${session.actualMinutes} '
                    '${AppStrings.studySessionMinutesUnit}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          AppStatusBadge(
            label: isCancelled
                ? AppStrings.sessionStatusCancelled
                : AppStrings.sessionStatusCompleted,
            backgroundColor: isCancelled
                ? AppColors.textSecondary.withValues(alpha: 0.12)
                : AppColors.success.withValues(alpha: 0.12),
            foregroundColor: isCancelled
                ? AppColors.textSecondary
                : AppColors.success,
          ),
        ],
      ),
    );
  }
}
