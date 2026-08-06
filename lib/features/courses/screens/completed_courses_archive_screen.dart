// lib/features/courses/screens/completed_courses_archive_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/error_state.dart';
import '../providers/course_provider.dart';
import '../widgets/archived_course_card.dart';

class CompletedCoursesArchiveScreen extends StatefulWidget {
  const CompletedCoursesArchiveScreen({super.key});

  @override
  State<CompletedCoursesArchiveScreen> createState() =>
      _CompletedCoursesArchiveScreenState();
}

class _CompletedCoursesArchiveScreenState
    extends State<CompletedCoursesArchiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
    });
  }

  void _handleNavigation(int index) {
    handleMainNavigation(context, index, currentIndex: 1);
  }

  void _showFilterUnderDevelopment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.screenUnderDevelopment),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final archivedCourses = courseProvider.archivedCourses;

    if (courseProvider.isLoadingCourses && archivedCourses.isEmpty) {
      return _buildScaffold(
        body: const AppLoadingState(message: AppStrings.coursesLoadError),
      );
    }

    if (courseProvider.coursesErrorMessage != null && archivedCourses.isEmpty) {
      return _buildScaffold(
        body: AppErrorState(
          message: courseProvider.coursesErrorMessage!,
          onRetry: () {
            context.read<CourseProvider>().loadCourses(forceRefresh: true);
          },
        ),
      );
    }

    return _buildScaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(archivedCourses.length),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: archivedCourses.isEmpty
                  ? const Center(
                child: Text(
                  AppStrings.noArchivedCoursesMessage,
                  style: AppTextStyles.bodyMedium,
                ),
              )
                  : ListView.separated(
                itemCount: archivedCourses.length,
                separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.medium),
                itemBuilder: (context, index) {
                  return ArchivedCourseCard(
                    course: archivedCourses[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaffold({required Widget body}) {
    return AuthenticatedPageScaffold(
      currentIndex: 1,
      onNavigationTap: _handleNavigation,
      appBar: const AcademiaSubAppBar(title: AppStrings.coursesArchiveTitle),
      body: body,
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: _showFilterUnderDevelopment,
          icon: const Icon(Icons.filter_list_rounded, color: AppColors.primary),
          label: const Text(
            AppStrings.coursesArchiveFilterLabel,
            style: TextStyle(color: AppColors.primary),
          ),
        ),
        Text(
          '${AppStrings.coursesArchiveCompletedPrefix} $count '
              '${AppStrings.coursesArchiveCompletedSuffix}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}