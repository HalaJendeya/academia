import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../assignments/providers/assignment_progress_provider.dart';
import '../../assignments/providers/course_assignment_provider.dart';
import '../../courses/providers/student_courses_provider.dart';
import '../../study/providers/study_session_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../models/analytics_summary.dart';
import '../models/study_duration_format.dart';

/// لوحة التحليلات.
///
/// كل رقم هنا محسوب من مستندات الطالب المخزَّنة: مهامه الشخصية، وعلامات
/// إنجازه على الواجبات، وجلسات مذاكرته المكتملة. لا قيم ثابتة، ولا أهداف
/// مفترضة، ولا اتجاهات أسبوعية — تلك كانت أرقامًا مكتوبة في الشيفرة تُعرض
/// كأنها قياس.
///
/// الشاشة للقراءة فقط: تقرأ من مزوّدات قائمة ولا تكتب شيئًا، ولا تفتح
/// مستمعًا خاصًا بها. المزوّدات الأربعة محمَّلة أصلًا لجلسة الطالب، فلا
/// حاجة لخدمة تحليلات ولا لاستعلام إضافي.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  void _handleNavigation(BuildContext context, int index) {
    handleMainNavigation(context, index, currentIndex: 4);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    final assignments = context.watch<CourseAssignmentProvider>();
    final progress = context.watch<AssignmentProgressProvider>();
    final sessions = context.watch<StudySessionProvider>();
    final courses = context.watch<StudentCoursesProvider>();

    final summary = AnalyticsSummary.from(
      tasks: tasks.tasks,
      // النشطة وحدها: المؤرشف أزاله المعلّم، فلا يُحتسب مطلوبًا من الطالب.
      assignments: assignments.activeAssignments,
      completedAssignmentIds: progress.completedAssignmentIds,
      sessions: sessions.sessions,
    );

    /*
     * التحميل يُعرض فقط عندما لا يوجد ما يُعرض بعد.
     *
     * الصفر بيانات صحيحة لا حالة انتظار: طالب لم ينجز شيئًا يجب أن يرى
     * أصفارًا صادقة، لا دوّامة تحميل أبدية.
     */
    final isLoading =
        (tasks.isLoading || assignments.isLoading || sessions.isLoading) &&
        summary.isEmpty;

    return AuthenticatedPageScaffold(
      currentIndex: 4,
      onNavigationTap: (index) => _handleNavigation(context, index),
      appBar: const AcademiaSubAppBar(
        title: AppStrings.analyticsDashboardTitle,
      ),
      body: isLoading
          ? const AppLoadingState()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.screenVertical,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.large),

                    // نفس تخطيط البطاقتين الأصلي: صف على الشاشات العريضة،
                    // وعمود على الضيقة.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useRow = constraints.maxWidth >= 500;
                        final workCard = _buildCompletedWorkCard(summary);
                        final hoursCard = _buildStudyTimeCard(summary);

                        if (useRow) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: workCard),
                              const SizedBox(width: AppSpacing.medium),
                              Expanded(child: hoursCard),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            workCard,
                            const SizedBox(height: AppSpacing.medium),
                            hoursCard,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    _buildCompletionRateCard(summary),

                    // بطاقة أكثر مساق تظهر فقط إذا وُجد ما يملؤها.
                    if (summary.hasMostStudiedCourse) ...[
                      const SizedBox(height: AppSpacing.medium),
                      _buildMostStudiedCourseCard(summary, courses),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.analyticsDashboardTitle,
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.analyticsDashboardDescription,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.analyticsCumulativeNote,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  /// بطاقة الأعمال المنجزة: مهام شخصية + واجبات أكاديمية.
  Widget _buildCompletedWorkCard(AnalyticsSummary summary) {
    return _MetricCard(
      icon: Icons.check_circle_rounded,
      title: AppStrings.completedWorkTitle,
      value: '${summary.completedWork}',
      // التفصيل يمنع الالتباس: الرقم أعلاه يضم نوعين، والسطر يوضح أيهما.
      detail:
          '${AppStrings.completedTasksTitle}: ${summary.completedTasks}'
          '  ·  '
          '${AppStrings.completedAssignmentsTitle}: '
          '${summary.completedAssignments}',
    );
  }

  Widget _buildStudyTimeCard(AnalyticsSummary summary) {
    return _MetricCard(
      icon: Icons.schedule_rounded,
      title: AppStrings.studyHoursTitle,
      value: StudyDurationFormat.format(summary.studiedMinutes),
      detail: summary.hasStudyTime
          ? null
          : AppStrings.analyticsNoStudySessions,
    );
  }

  /// نسبة الإنجاز — لا «نسبة الالتزام».
  ///
  /// الاسم يطابق ما يُحسب فعلًا: أعمال منجزة على أعمال مطلوبة. ولا تُعرض
  /// النسبة أصلًا بلا مقام.
  Widget _buildCompletionRateCard(AnalyticsSummary summary) {
    final rate = summary.completionRate;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.completionRateTitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          if (rate == null)
            Text(
              AppStrings.analyticsNoCompletionRate,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rate,
                      backgroundColor: const Color(0xFFF1F3F4),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.secondary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(rate * 100).round()}%',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // الكسر معروض صراحةً: النسبة وحدها تخفي حجم العيّنة.
            Text(
              '${summary.completedWork} ${AppStrings.completionRateOf} '
              '${summary.totalWork}',
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

  Widget _buildMostStudiedCourseCard(
    AnalyticsSummary summary,
    StudentCoursesProvider courses,
  ) {
    // الاسم يُحلّ من مساقات الطالب؛ تعذّر الحلّ يعني عدم عرض البطاقة بدل
    // عرض معرّف لا يقرأه أحد.
    String? title;
    for (final course in courses.currentCourses) {
      if (course.courseId == summary.mostStudiedCourseId) {
        title = course.title.isEmpty ? course.courseCode : course.title;
      }
    }
    if (title == null || title.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFFFF9800)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.mostStudiedCourseTitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 4),
          Text(
            StudyDurationFormat.format(summary.mostStudiedCourseMinutes),
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

/// بطاقة رقم واحد، بنفس شكل البطاقتين الأصليتين بعد نزع شارات الاتجاه
/// والهدف المختلقة.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.secondary, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
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
