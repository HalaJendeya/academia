// lib/features/courses/screens/course_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import '../providers/course_file_provider.dart';
import '../providers/course_provider.dart';
import '../widgets/assignment_preview_card.dart';
import '../widgets/course_header_card.dart';
import '../widgets/file_list_item_card.dart';
import '../widgets/next_session_card.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final TextEditingController _fileSearchController = TextEditingController();

  String? _courseId;
  String _fileSearchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final courseId = ModalRoute.of(context)?.settings.arguments as String?;
    if (courseId != null && courseId != _courseId) {
      _courseId = courseId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CourseProvider>().loadCourseDetail(courseId);
        context.read<CourseProvider>().loadCourseAssignments(courseId);
        context.read<CourseFileProvider>().loadFiles(courseId);
      });
    }
  }

  @override
  void dispose() {
    _fileSearchController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    handleMainNavigation(context, index, currentIndex: 1);
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final course = courseProvider.selectedCourse;

    if (courseProvider.isLoadingCourseDetail && course == null) {
      return _buildScaffold(
        body: const AppLoadingState(message: AppStrings.courseDetailLoadError),
      );
    }

    if (courseProvider.courseDetailErrorMessage != null && course == null) {
      return _buildScaffold(
        body: AppErrorState(
          message: courseProvider.courseDetailErrorMessage!,
          onRetry: () {
            if (_courseId != null) {
              context.read<CourseProvider>().loadCourseDetail(
                _courseId!,
                forceRefresh: true,
              );
            }
          },
        ),
      );
    }

    if (course == null) return _buildScaffold(body: const SizedBox.shrink());

    return _buildScaffold(
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverviewTab(course.id),
                  _buildAssignmentsTab(),
                  _buildFilesTab(),
                  _buildSharedSpaceTab(),
                ],
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
      appBar: const AcademiaSubAppBar(title: AppStrings.courseDetailAppBarTitle),
      body: body,
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: const TabBar(
        isScrollable: false,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        tabs: [
          Tab(text: AppStrings.courseOverviewTab),
          Tab(text: AppStrings.courseAssignmentsTab),
          Tab(text: AppStrings.courseFilesTab),
          Tab(text: AppStrings.courseSharedSpaceTab),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(String courseId) {
    final courseProvider = context.watch<CourseProvider>();
    final fileProvider = context.watch<CourseFileProvider>();
    final course = courseProvider.selectedCourse!;
    final firstAssignment = courseProvider.courseAssignments.isNotEmpty
        ? courseProvider.courseAssignments.first
        : null;
    final firstFile = fileProvider.files.isNotEmpty
        ? fileProvider.files.first
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CourseHeaderCard(course: course),
          const SizedBox(height: AppSpacing.medium),
          NextSessionCard(course: course),
          if (course.hasNextSession) const SizedBox(height: AppSpacing.medium),
          if (firstAssignment != null) ...[
            AssignmentPreviewCard(assignment: firstAssignment),
            const SizedBox(height: AppSpacing.medium),
          ],
          if (firstFile != null) FileListItemCard(file: firstFile),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    final courseProvider = context.watch<CourseProvider>();

    if (courseProvider.isLoadingAssignments &&
        courseProvider.courseAssignments.isEmpty) {
      return const AppLoadingState(
        message: AppStrings.courseAssignmentsLoadError,
      );
    }

    if (courseProvider.assignmentsErrorMessage != null &&
        courseProvider.courseAssignments.isEmpty) {
      return AppErrorState(
        message: courseProvider.assignmentsErrorMessage!,
        onRetry: () {
          if (_courseId != null) {
            context.read<CourseProvider>().loadCourseAssignments(
              _courseId!,
              forceRefresh: true,
            );
          }
        },
      );
    }

    if (courseProvider.courseAssignments.isEmpty) {
      return const Center(
        child: Text(
          AppStrings.noAssignmentsFoundMessage,
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: courseProvider.courseAssignments.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.medium),
      itemBuilder: (context, index) {
        return AssignmentPreviewCard(
          assignment: courseProvider.courseAssignments[index],
        );
      },
    );
  }

  Widget _buildFilesTab() {
    final fileProvider = context.watch<CourseFileProvider>();

    if (fileProvider.isLoading && fileProvider.files.isEmpty) {
      return const AppLoadingState(message: AppStrings.courseFilesLoadError);
    }

    if (fileProvider.errorMessage != null && fileProvider.files.isEmpty) {
      return AppErrorState(
        message: fileProvider.errorMessage!,
        onRetry: () {
          if (_courseId != null) {
            context.read<CourseFileProvider>().loadFiles(
              _courseId!,
              forceRefresh: true,
            );
          }
        },
      );
    }

    final query = _fileSearchQuery.toLowerCase();
    final filteredFiles = query.isEmpty
        ? fileProvider.files
        : fileProvider.files
        .where((file) => file.title.toLowerCase().contains(query))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFileSearchField(),
          const SizedBox(height: AppSpacing.medium),
          Expanded(
            child: filteredFiles.isEmpty
                ? const Center(
              child: Text(
                AppStrings.noFilesFoundMessage,
                style: AppTextStyles.bodyMedium,
              ),
            )
                : ListView.separated(
              itemCount: filteredFiles.length,
              separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.small),
              itemBuilder: (context, index) {
                return FileListItemCard(file: filteredFiles[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSearchField() {
    return TextField(
      controller: _fileSearchController,
      textAlign: TextAlign.right,
      style: AppTextStyles.bodyMedium,
      onChanged: (value) {
        setState(() => _fileSearchQuery = value.trim());
      },
      decoration: InputDecoration(
        hintText: AppStrings.fileSearchHint,
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

  Widget _buildSharedSpaceTab() {
    return const Center(
      child: Text(
        AppStrings.screenUnderDevelopment,
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}
