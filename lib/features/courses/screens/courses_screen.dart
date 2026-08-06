// lib/features/courses/screens/courses_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/error_state.dart';
import '../models/course.dart';
import '../providers/course_provider.dart';
import '../widgets/course_card.dart';
import '../widgets/course_status_tabs.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = Course.statusActive;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    handleMainNavigation(context, index, currentIndex: 1);
  }

  void _showFilesUnderDevelopment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.screenUnderDevelopment),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openCourseDetail(String courseId) {
    Navigator.pushNamed(context, AppRoutes.courseDetail, arguments: courseId);
  }

  List<Course> _filterCourses(List<Course> courses) {
    if (_searchQuery.isEmpty) return courses;
    final query = _searchQuery.toLowerCase();
    return courses.where((course) {
      return course.title.toLowerCase().contains(query) ||
          course.instructorName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();

    final hasNoData =
        courseProvider.activeCourses.isEmpty &&
            courseProvider.archivedCourses.isEmpty;

    if (courseProvider.isLoadingCourses && hasNoData) {
      return _buildScaffold(
        body: const AppLoadingState(message: AppStrings.coursesLoadError),
      );
    }

    if (courseProvider.coursesErrorMessage != null && hasNoData) {
      return _buildScaffold(
        body: AppErrorState(
          message: courseProvider.coursesErrorMessage!,
          onRetry: () {
            context.read<CourseProvider>().loadCourses(forceRefresh: true);
          },
        ),
      );
    }

    final sourceCourses = _selectedStatus == Course.statusActive
        ? courseProvider.activeCourses
        : courseProvider.archivedCourses;
    final filteredCourses = _filterCourses(sourceCourses);

    return _buildScaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.medium),
              _buildSearchField(),
              const SizedBox(height: AppSpacing.medium),
              CourseStatusTabs(
                selectedStatus: _selectedStatus,
                onStatusChanged: (status) {
                  setState(() => _selectedStatus = status);
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              if (filteredCourses.isEmpty)
                _buildEmptyState()
              else
                ...filteredCourses.map(
                      (course) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: CourseCard(
                      course: course,
                      onTap: () => _openCourseDetail(course.id),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.large),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold({required Widget body}) {
    return AuthenticatedPageScaffold(
      currentIndex: 1,
      onNavigationTap: _handleNavigation,
      appBar: const AcademiaMainAppBar(
        title: AppStrings.appName,
        showProfile: true,
        showSearch: false,
        showNotifications: true,
      ),
      body: body,
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            AppStrings.myCoursesTitle,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Flexible(
          fit: FlexFit.loose,
          child: ElevatedButton(
            onPressed: _showFilesUnderDevelopment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
                vertical: AppSpacing.small,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: const Text(AppStrings.coursesFilesButtonLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textAlign: TextAlign.right,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: AppStrings.courseSearchHint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDisabled,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.extraLarge),
      child: Center(
        child: Text(
          AppStrings.noCoursesFoundMessage,
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}