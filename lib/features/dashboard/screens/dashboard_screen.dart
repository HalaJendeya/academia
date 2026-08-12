import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../../courses/providers/student_courses_provider.dart';
import '../widgets/ai_recommendation_card.dart';
import '../widgets/dashboard_courses_summary_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/today_tasks_card.dart';

/// لوحة الطالب: شاشة تجميع لا مجال بيانات جديد.
///
/// كل رقم فيها مشتق من مزوّد محمَّل مسبقًا، ولا تُطلق قراءة جديدة عند كل
/// إعادة بناء. الهوية تُعرض دائمًا حتى لو فشل تحميل المساقات، لأن فقدان
/// جزء لا يبرّر إفراغ الشاشة كلها.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _handleNavigation(BuildContext context, int index) {
    handleMainNavigation(
      context,
      index,
      currentIndex: AcademiaBottomNavigation.homeIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final courses = context.watch<StudentCoursesProvider>();
    final user = auth.currentUserProfile;

    return AuthenticatedPageScaffold(
      currentIndex: AcademiaBottomNavigation.homeIndex,
      onNavigationTap: (index) => _handleNavigation(context, index),
      /*
       * صورة الحساب تفتح الملف الشخصي. كانت ظاهرة بلا وجهة، فتبدو قابلة
       * للضغط ولا تفعل شيئًا.
       *
       * جرس التنبيهات ما زال بلا وجهة: لا شاشة تنبيهات بعد، وربطه بشيء
       * الآن يعني اختراع وجهة لا وجود لها.
       */
      appBar: AcademiaMainAppBar(
        title: AppStrings.appName,
        showProfile: true,
        showSearch: false,
        showNotifications: true,
        onProfilePressed: () =>
            Navigator.pushNamed(context, AppRoutes.profile),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.screenVertical,
          AppSpacing.screenHorizontal,
          AppSpacing.huge,
        ),
        children: [
          DashboardHeader(
            fullName: user?.fullName ?? '',
            academicLevel: user?.academicLevel,
            majorName: courses.hasMajor && courses.major != null
                ? courses.majorName
                : null,
          ),
          const SizedBox(height: AppSpacing.medium),
          _buildSemesterCard(courses),
          const SizedBox(height: AppSpacing.medium),

          // قسم المساقات وحده هو ما يتأثر بفشل تحميل البيانات الأكاديمية.
          ..._buildAcademicSections(context, courses),

          const SizedBox(height: AppSpacing.medium),
          const TodayTasksCard(),

          const SizedBox(height: AppSpacing.large),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildSemesterCard(StudentCoursesProvider courses) {
    // الفصل الحالي يُحدَّد بحالته المخزَّنة، لا بمقارنة التواريخ.
    final semester = courses.currentSemester;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.dashboardSemesterLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 2),
                Text(
                  semester?.semesterName ?? AppStrings.dashboardNoSemester,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          if (semester != null)
            AppStatusBadge(
              label: AppStrings.semesterStatusCurrent,
              backgroundColor: AppColors.activeStatus.withValues(alpha: 0.08),
              foregroundColor: AppColors.activeStatus,
              icon: Icons.event_available_rounded,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildAcademicSections(
    BuildContext context,
    StudentCoursesProvider courses,
  ) {
    if (courses.isLoading && !courses.hasLoaded) {
      return const [
        SizedBox(height: 160, child: AppLoadingState()),
      ];
    }

    if (courses.errorMessage != null && !courses.hasLoaded) {
      return [
        AppCard(
          child: Text(
            courses.errorMessage!,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            textAlign: TextAlign.right,
          ),
        ),
      ];
    }

    return [
      PlanSummaryCard(
        hasMajor: courses.hasMajor,
        totalCreditHours: courses.programTotalCreditHours,
        academicLevel: courses.academicLevel,
        levelCreditHours: courses.recommendedCreditHours,
      ),
      const SizedBox(height: AppSpacing.medium),
      DashboardCoursesSummaryCard(
        currentCount: courses.currentCourses.length,
        availableCount: courses.availableNow.length,
        hasCurrentSemester: courses.hasCurrentSemester,
        onOpenCourses: () =>
            Navigator.pushReplacementNamed(context, AppRoutes.courses),
      ),
      if (courses.hasMajor) ...[
        const SizedBox(height: AppSpacing.medium),
        LevelRecommendationCard(
          entries: courses.recommendedForMyLevel,
          onEntryTap: (entry) {
            final courseId = entry.entry.courseId;
            if (courseId == null) return;
            Navigator.pushNamed(context, AppRoutes.courses);
          },
        ),
      ],
    ];
  }

  Widget _buildQuickActions(BuildContext context) {
    // وجهات عاملة فقط: المهام والدراسة ما زالتا غير منفَّذتين.
    final actions = <({IconData icon, String label, String route})>[
      (
        icon: Icons.school_rounded,
        label: AppStrings.dashboardActionCourses,
        route: AppRoutes.courses,
      ),
      (
        icon: Icons.person_outline_rounded,
        label: AppStrings.dashboardActionProfile,
        route: AppRoutes.profile,
      ),
      (
        icon: Icons.menu_book_rounded,
        label: AppStrings.dashboardActionStudyPreferences,
        route: AppRoutes.studyPreferences,
      ),
      (
        icon: Icons.notifications_none_rounded,
        label: AppStrings.dashboardActionNotifications,
        route: AppRoutes.profileNotificationSettings,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.dashboardQuickActionsTitle,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: AppSpacing.small),
        // شبكة بعمودين: أربعة إجراءات لا تتسع في صف واحد على عرض 360.
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.medium,
          crossAxisSpacing: AppSpacing.medium,
          // نسبة منخفضة عمدًا: التسميات العربية قد تلتف على سطرين، والبلاطة
          // القصيرة تفيض رأسيًا على عرض 360.
          childAspectRatio: 1.45,
          children: [
            for (final action in actions)
              QuickActionCard(
                icon: action.icon,
                label: action.label,
                onTap: () {
                  if (action.route == AppRoutes.courses) {
                    Navigator.pushReplacementNamed(context, action.route);
                  } else {
                    Navigator.pushNamed(context, action.route);
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}
