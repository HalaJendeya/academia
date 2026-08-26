import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_menu_tile.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../analytics/models/study_duration_format.dart';
import '../../courses/providers/student_courses_provider.dart';
import '../models/study_history_summary.dart';
import '../models/weekly_study_summary.dart';
import '../providers/study_session_provider.dart';
import '../widgets/study_session_card.dart';

/// مركز المذاكرة — إطار Figma‏ 11:416، تبويب «المذاكرة» في الشريط السفلي.
///
/// البطاقتان العلويتان والدعوة البرتقالية وقسم القائمة تتبع التصميم، لكن
/// أرقامها محسوبة من جلسات الطالب المخزَّنة لا من عيّنات.
///
/// انحراف مقصود: يعرض التصميم «الجدول القادم» بجلسات مجدولة مسبقًا بموعد
/// ومكان. لا يعرف النظام جلسة قبل بدئها — الجلسة تُنشأ وتنطلق فورًا — فلا
/// بيانات تملأ ذلك القسم. وُضع مكانه «آخر الجلسات» من بيانات حقيقية، وفُصِل
/// الجدولة كعمل مستقبلي بدل اختلاق مواعيد.
class StudyHubScreen extends StatelessWidget {
  const StudyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<StudySessionProvider>();
    final courses = context.watch<StudentCoursesProvider>();

    // إحصاءات العمر للبطاقة الأولى، وإحصاءات الأسبوع للثانية — كما في
    // التصميم، وكلٌّ مُسمّى بما يقيسه بالضبط.
    final lifetime = StudyHistorySummary.from(sessions: sessions.sessions);
    final weekly = WeeklyStudySummary.from(
      sessions: sessions.sessions,
      tasks: const [],
      assignmentCompletionTimes: const {},
    );

    return AuthenticatedPageScaffold(
      currentIndex: AcademiaBottomNavigation.studyIndex,
      onNavigationTap: (index) => handleMainNavigation(
        context,
        index,
        currentIndex: AcademiaBottomNavigation.studyIndex,
      ),
      appBar: const AcademiaMainAppBar(
        title: AppStrings.studySessionsTitle,
        showSearch: false,
        showNotifications: false,
        showProfile: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.medium,
          AppSpacing.screenHorizontal,
          AppSpacing.huge,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: AppStrings.completedSessionsLabel,
                  value:
                      '${lifetime.completedSessions} '
                      '${AppStrings.sessionsCountUnit}',
                ),
              ),
              const SizedBox(width: AppSpacing.itemSpacing),
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_outlined,
                  label: AppStrings.weeklyStudyMinutesLabel,
                  value: StudyDurationFormat.format(weekly.studiedMinutes),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),

          _StartSessionHero(
            hasActiveSession: sessions.hasActiveSession,
            onTap: () => Navigator.of(context).pushNamed(
              sessions.hasActiveSession
                  ? AppRoutes.activeStudySession
                  : AppRoutes.createStudySession,
            ),
          ),
          const SizedBox(height: AppSpacing.large),

          _ToolsSection(),
          const SizedBox(height: AppSpacing.large),

          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.recentSessionsHeading,
                  style: AppTextStyles.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.sessionHistory),
                child: const Text(AppStrings.viewAllAction),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          _RecentSessions(sessions: sessions, courses: courses),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.itemSpacing),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// الدعوة البرتقالية «ابدأ جلسة دراسة».
///
/// تتحوّل إلى «عودة إلى الجلسة» متى كانت هناك جلسة جارية: بدء ثانية مرفوض
/// أصلًا، ووعد الزر يجب أن يطابق ما سيحدث.
class _StartSessionHero extends StatelessWidget {
  const _StartSessionHero({
    required this.hasActiveSession,
    required this.onTap,
  });

  final bool hasActiveSession;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFFFF9800)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hasActiveSession
                  ? AppStrings.activeSessionTitle
                  : AppStrings.startSessionHeroTitle,
              style: AppTextStyles.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.startSessionHeroSubtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: AppSpacing.medium),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.small + 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasActiveSession
                          ? AppStrings.resumeSessionAction
                          : AppStrings.startStudySession,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// روابط أدوات المذاكرة — كل واحد يفتح شاشة حقيقية.
class _ToolsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.studyToolsTitle,
          style: AppTextStyles.sectionTitle,
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: AppSpacing.itemSpacing),
        AppMenuTile(
          icon: Icons.insights_outlined,
          title: AppStrings.weeklyReportTile,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.weeklySummary),
        ),
        AppMenuTile(
          icon: Icons.history_rounded,
          title: AppStrings.sessionHistoryTile,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.sessionHistory),
        ),
        AppMenuTile(
          icon: Icons.event_note_outlined,
          title: AppStrings.studyPlanTile,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.studyPlan),
        ),
        AppMenuTile(
          icon: Icons.tune_rounded,
          title: AppStrings.studyPreferencesTile,
          // لا نموذج تفضيلات ثانٍ: يُفتح النموذج القائم نفسه.
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.studyPreferences),
        ),
      ],
    );
  }
}

class _RecentSessions extends StatelessWidget {
  const _RecentSessions({required this.sessions, required this.courses});

  final StudySessionProvider sessions;
  final StudentCoursesProvider courses;

  String? _titleFor(String? courseId) {
    if (courseId == null) return null;
    for (final course in courses.currentCourses) {
      if (course.courseId == courseId) {
        return course.title.isEmpty ? course.courseCode : course.title;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (sessions.isLoading && sessions.sessions.isEmpty) {
      return const AppLoadingState();
    }
    if (sessions.errorMessage != null && sessions.sessions.isEmpty) {
      return AppErrorState(message: sessions.errorMessage!);
    }

    final recent = sessions.recentSessions(limit: 3);
    if (recent.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.noStudySessionsTitle,
        description: AppStrings.noStudySessionsDesc,
        icon: Icons.history_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final session in recent) ...[
          StudySessionCard(
            session: session,
            courseTitle: _titleFor(session.courseId),
          ),
          if (session != recent.last)
            const SizedBox(height: AppSpacing.itemSpacing),
        ],
      ],
    );
  }
}
