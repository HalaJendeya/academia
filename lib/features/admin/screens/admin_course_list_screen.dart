import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_destructive_button.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../courses/models/course_model.dart';
import '../../courses/providers/course_provider.dart';

class AdminCourseListScreen extends StatefulWidget {
  const AdminCourseListScreen({super.key});

  @override
  State<AdminCourseListScreen> createState() => _AdminCourseListScreenState();
}

class _AdminCourseListScreenState extends State<AdminCourseListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'archived'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseProvider>().listenToCourses();
    });
  }

  void _showArchiveDialog(BuildContext context, CourseModel course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          AppStrings.archiveCourseTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: const Text(
          AppStrings.archiveCourseConfirm,
          textAlign: TextAlign.right,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final provider = context.read<CourseProvider>();
                final success = await provider.archiveCourse(course.id);
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.courseArchivedSuccess),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? AppStrings.courseSaveError,
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text(AppStrings.confirmAction),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancelAction),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, CourseModel course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          AppStrings.deleteAction,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: const Text(
          AppStrings.deleteCourseConfirm,
          textAlign: TextAlign.right,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: AppDestructiveButton(
              label: AppStrings.confirmAction,
              filled: true,
              onPressed: () async {
                Navigator.of(ctx).pop();
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final provider = context.read<CourseProvider>();
                final success = await provider.deleteCourse(course.id);
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.courseDeletedSuccess),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? AppStrings.courseSaveError,
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancelAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminCoursesTitle),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          provider.selectCourse(null);
          Navigator.of(context).pushNamed(AppRoutes.adminAddCourse);
        },
        label: const Text(AppStrings.addCourseLabel),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: AppStrings.searchCourseHint,
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.medium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildFilterChip('all', AppStrings.filterAll),
                    const SizedBox(width: 8),
                    _buildFilterChip('active', AppStrings.filterActive),
                    const SizedBox(width: 8),
                    _buildFilterChip('archived', AppStrings.filterArchived),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterVal, String label) {
    final isSelected = _statusFilter == filterVal;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _statusFilter = filterVal;
          });
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildBody(CourseProvider provider) {
    if (provider.isLoading) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () => provider.listenToCourses(),
      );
    }

    final filtered = provider.courses.where((course) {
      final matchesSearch =
          course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          course.courseCode.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _statusFilter == 'all' ||
          (_statusFilter == 'active' && course.isActive) ||
          (_statusFilter == 'archived' && course.isArchived);
      return matchesSearch && matchesStatus;
    }).toList();

    if (filtered.isEmpty) {
      return AppEmptyState(
        title: AppStrings.noCoursesFound,
        icon: Icons.menu_book_rounded,
        actionLabel: AppStrings.addCourseLabel,
        onAction: () {
          provider.selectCourse(null);
          Navigator.of(context).pushNamed(AppRoutes.adminAddCourse);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final course = filtered[index];
        return _buildCourseCard(course, provider);
      },
    );
  }

  Widget _buildCourseCard(CourseModel course, CourseProvider provider) {
    final statusColor = course.isActive
        ? AppColors.activeStatus
        : AppColors.textMuted;
    final statusBgColor = statusColor.withValues(alpha: 0.08);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: course.isActive
                    ? AppStrings.activeStatus
                    : AppStrings.archivedStatus,
                backgroundColor: statusBgColor,
                foregroundColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Icon(
                Icons.code_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                course.courseCode,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${AppStrings.instructorNameLabel}: ${course.instructorName}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${AppStrings.semesterLabel} ${course.semester} - ${course.academicYear}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.adminCourseDetails, arguments: course);
                },
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text(AppStrings.viewAction),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                tooltip: AppStrings.editAction,
                onPressed: () {
                  provider.selectCourse(course);
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.adminEditCourse, arguments: course);
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.archive_rounded,
                  color: course.isArchived
                      ? AppColors.textDisabled
                      : AppColors.secondary,
                ),
                tooltip: AppStrings.archiveAction,
                onPressed: course.isArchived
                    ? null
                    : () => _showArchiveDialog(context, course),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.danger,
                ),
                tooltip: AppStrings.deleteAction,
                onPressed: () => _showDeleteDialog(context, course),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
