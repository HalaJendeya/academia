import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/student_course_view.dart';
import '../providers/student_courses_provider.dart';
import '../widgets/student_attempt_card.dart';
import 'student_course_detail_screen.dart';

/// السجل الدراسي كاملًا في صفحة مستقلة.
///
/// نفس لغة أرشيف فريق الواجهة، لكن الوحدة هنا المحاولة لا المساق: إعادة
/// دراسة مساق تُعرض محاولتين منفصلتين تحت عنوان المساق نفسه.
class StudentCoursesArchiveScreen extends StatelessWidget {
  const StudentCoursesArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentCoursesProvider>();
    final grouped = provider.historyByCourse;

    return AuthenticatedPageScaffold(
      currentIndex: AcademiaBottomNavigation.coursesIndex,
      onNavigationTap: (index) => handleMainNavigation(
        context,
        index,
        currentIndex: AcademiaBottomNavigation.coursesIndex,
      ),
      appBar: const AcademiaSubAppBar(title: AppStrings.coursesArchiveTitle),
      body: grouped.isEmpty
          ? const AppEmptyState(
              title: AppStrings.historyEmptyTitle,
              description: AppStrings.historyEmptyDesc,
              icon: Icons.history_rounded,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.medium,
                AppSpacing.screenHorizontal,
                AppSpacing.huge,
              ),
              children: [
                for (final entry in grouped.entries)
                  ..._buildGroup(context, entry.value),
              ],
            ),
    );
  }

  List<Widget> _buildGroup(
    BuildContext context,
    List<StudentCourseView> attempts,
  ) {
    final first = attempts.first;

    return [
      Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.small,
          bottom: AppSpacing.extraSmall,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                first.hasCourse ? first.title : AppStrings.unknownCourse,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (attempts.length > 1)
              Text(
                '${AppStrings.attemptsCountLabel}: ${attempts.length}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
      ...attempts.map(
        (attempt) => StudentAttemptCard(
          view: attempt,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.courseDetail,
            arguments: StudentCourseDetailArgs(
              courseId: attempt.courseId,
              offeringId: attempt.offeringId,
            ),
          ),
        ),
      ),
    ];
  }
}
