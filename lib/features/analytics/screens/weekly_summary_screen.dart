import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../assignments/providers/assignment_progress_provider.dart';
import '../../study/models/study_week.dart';
import '../../study/models/weekly_study_summary.dart';
import '../../study/providers/study_session_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../models/study_duration_format.dart';

/// الملخص الأسبوعي — إطار Figma‏ 143:23.
///
/// 🔴 أسبوعي فعلًا، لا إجماليات عمر مُعاد تسميتها. الأسبوع من السبت إلى
/// الجمعة (ترتيب أيام المذاكرة نفسه)، والانتماء يُقاس بطوابع زمنية مخزَّنة:
/// `startedAt` للجلسات، و`completedAt` للمهام وعلامات إنجاز الواجبات.
///
/// ما لا مصدر له حُذف من التصميم: بطاقة «تجاوزت هدفك الأسبوعي» تفترض هدفًا
/// لا وجود له في النظام. أما المقارنة بالأسبوع الماضي فبقيت لأنها محسوبة
/// حقًّا من جلسات الأسبوع السابق، وتختفي وحدها إن لم يكن لذلك الأسبوع رصيد.
class WeeklySummaryScreen extends StatelessWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<StudySessionProvider>();
    final tasks = context.watch<TaskProvider>();
    final progress = context.watch<AssignmentProgressProvider>();

    final summary = WeeklyStudySummary.from(
      sessions: sessions.sessions,
      tasks: tasks.tasks,
      assignmentCompletionTimes: progress.completionTimes,
    );

    final loading =
        (sessions.isLoading || tasks.isLoading) &&
        sessions.sessions.isEmpty &&
        tasks.tasks.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AcademiaSubAppBar(
        title: AppStrings.weeklySummaryTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: loading
            ? const AppLoadingState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.medium,
                  AppSpacing.screenHorizontal,
                  AppSpacing.huge,
                ),
                children: [
                  _Header(summary: summary),
                  const SizedBox(height: AppSpacing.large),

                  if (summary.isEmpty)
                    const AppEmptyState(
                      title: AppStrings.weeklyEmptyTitle,
                      description: AppStrings.weeklyEmptyDesc,
                      icon: Icons.insights_outlined,
                    )
                  else ...[
                    _StudyHoursCard(summary: summary),
                    const SizedBox(height: AppSpacing.itemSpacing),
                    _BestDayCard(summary: summary),
                    const SizedBox(height: AppSpacing.itemSpacing),
                    _TasksOverviewCard(summary: summary),
                  ],
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.summary});

  final WeeklyStudySummary summary;

  @override
  Widget build(BuildContext context) {
    final start = summary.week.start;
    final end = summary.week.lastDay;
    // «من 15 أكتوبر إلى 21 أكتوبر» — مدى حقيقي مشتقّ من حدود الأسبوع.
    final range =
        '${AppStrings.weeklyRangePrefix} ${start.day} '
        '${ArabicMonth.of(start.month)} — ${end.day} '
        '${ArabicMonth.of(end.month)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.weeklySummaryTitle,
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 4),
        Text(
          range,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

class _StudyHoursCard extends StatelessWidget {
  const _StudyHoursCard({required this.summary});

  final WeeklyStudySummary summary;

  @override
  Widget build(BuildContext context) {
    final trend = summary.trendRatio;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  AppStrings.weeklyStudyHoursLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            StudyDurationFormat.format(summary.studiedMinutes),
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          /*
           * المقارنة تظهر فقط إن كان للأسبوع الماضي رصيد. بلا رصيد لا نسبة:
           * القسمة على صفر ليست «+100%»، وعرضها كذلك ادّعاء لا قياس.
           */
          if (trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  trend >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: trend >= 0 ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${trend >= 0 ? '+' : ''}${(trend * 100).round()}% '
                    '${AppStrings.weeklyVsLastWeek}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: trend >= 0 ? AppColors.success : AppColors.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _BestDayCard extends StatelessWidget {
  const _BestDayCard({required this.summary});

  final WeeklyStudySummary summary;

  @override
  Widget build(BuildContext context) {
    final day = ArabicWeekday.name(summary.bestWeekday);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  AppStrings.weeklyBestDayLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            day ?? '—',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          if (summary.hasBestDay) ...[
            const SizedBox(height: 4),
            // مجموع اليوم لا «مذاكرة متواصلة»: الجلسات قد تكون متفرّقة،
            // ووصفها بالتواصل ادّعاء لا يسنده التخزين.
            Text(
              StudyDurationFormat.format(summary.bestWeekdayMinutes),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }
}

class _TasksOverviewCard extends StatelessWidget {
  const _TasksOverviewCard({required this.summary});

  final WeeklyStudySummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.weeklyTasksOverview,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: '${summary.overdueTasks}',
                  label: AppStrings.tasksOverdueLabel,
                  color: AppColors.error,
                ),
              ),
              Expanded(
                child: _Metric(
                  value: '${summary.pendingTasks}',
                  label: AppStrings.tasksPendingLabel,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _Metric(
                  value: '${summary.totalCompletedWork}',
                  label: AppStrings.tasksCompletedLabel,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          // «مكتملة» هنا أسبوعية، بينما «متأخرة/قيد التنفيذ» لقطة راهنة.
          // الفرق مذكور صراحةً بدل تركه للتخمين.
          Text(
            '${AppStrings.tasksCompletedLabel}: '
            '${AppStrings.weeklyCompletedThisWeek} · '
            '${AppStrings.weeklyCurrentSnapshotNote}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
