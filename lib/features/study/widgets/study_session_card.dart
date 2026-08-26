import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../models/study_session_model.dart';
import '../models/study_week.dart';

/// بطاقة جلسة في السجل — إطار Figma‏ 96:608.
///
/// كل ما تعرضه مخزَّن: الحالة، والعنوان، والتاريخ والوقت، والمدة الفعلية،
/// ونسبة ما تحقّق من المخطَّط. لا تقييم ولا نقاط.
class StudySessionCard extends StatelessWidget {
  const StudySessionCard({
    super.key,
    required this.session,
    this.courseTitle,
  });

  final StudySessionModel session;

  /// اسم المساق إن أمكن حلّه؛ الجلسة تخزّن المعرّف لا الاسم.
  final String? courseTitle;

  /// العنوان: اسم الجلسة، وإلا اسم المساق، وإلا «مذاكرة عامة».
  String get _title {
    final name = session.displayName;
    if (name != null) return name;
    final course = courseTitle?.trim();
    if (course != null && course.isNotEmpty) return course;
    return AppStrings.studyGeneralSession;
  }

  /// «25 يونيو 2026 • 10:30 صباحًا» — بالتقويم الميلادي وبأرقام لاتينية،
  /// كما يعرضه بقية التطبيق.
  static String formatDateTime(DateTime at) {
    final date = '${at.day} ${ArabicMonth.of(at.month)} ${at.year}';
    final isMorning = at.hour < 12;
    var hour = at.hour % 12;
    if (hour == 0) hour = 12;
    final minute = at.minute.toString().padLeft(2, '0');
    final period = isMorning ? 'صباحًا' : 'مساءً';
    return '$date • $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final cancelled = session.isCancelled;
    final accent = cancelled ? AppColors.textSecondary : AppColors.success;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppStatusBadge(
                label: cancelled
                    ? AppStrings.sessionStatusCancelledShort
                    : AppStrings.sessionStatusCompletedShort,
                backgroundColor: accent.withValues(alpha: 0.12),
                foregroundColor: accent,
              ),
              const SizedBox(width: AppSpacing.small),
              // Flexible: أسماء الجلسات والمساقات تطول، وعرض 360 لا يسامح.
              Flexible(
                child: Text(
                  _title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${session.actualMinutes} ${AppStrings.minutesUnit}',
                style: AppTextStyles.bodySmall,
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  formatDateTime(session.startedAt),
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          // شريط النسبة للمكتملة وحدها: الملغاة لم تُحتسب، وشريط بصفر
          // يوحي بقياس لم يحدث.
          if (!cancelled) ...[
            const SizedBox(height: AppSpacing.small),
            Row(
              children: [
                Text(
                  '${(session.completionRatio * 100).round()}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: LinearProgressIndicator(
                      value: session.completionRatio,
                      minHeight: 6,
                      backgroundColor: AppColors.borderLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
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
