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
import '../../auth/providers/auth_provider.dart';
import '../../courses/models/course_model.dart';
import '../../courses/providers/course_provider.dart';

class AdminCourseListScreen extends StatefulWidget {
  const AdminCourseListScreen({super.key});

  @override
  State<AdminCourseListScreen> createState() => _AdminCourseListScreenState();
}

class _AdminCourseListScreenState extends State<AdminCourseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn || !auth.isAdmin) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      } else {
        context.read<CourseProvider>().listenToCourses();
      }
    });
  }

  @override
  void dispose() {
    // Stop listening before super.dispose
    context.read<CourseProvider>().stopListening();
    super.dispose();
  }

  void _showArchiveDialog(BuildContext context, CourseModel course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'أرشفة المساق',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: const Text(
          AppStrings.archiveCourseConfirm,
          textAlign: TextAlign.right,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancelAction),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final provider = context.read<CourseProvider>();
              final success = await provider.archiveCourse(course.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.courseArchivedSuccess),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? AppStrings.courseSaveError,
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text(AppStrings.confirmAction),
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
          'حذف المساق نهائياً',
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
                final provider = context.read<CourseProvider>();
                final success = await provider.deleteCourse(course.id);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.courseDeletedSuccess),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.errorMessage ?? AppStrings.courseSaveError,
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
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
    final auth = context.watch<AuthProvider>();

    // Guard: Render loading indicator and avoid building admin UI if not admin
    if (!auth.isLoggedIn || !auth.isAdmin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final provider = context.watch<CourseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminCoursesTitle),
        centerTitle: true,
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
      body: _buildBody(provider),
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

    if (provider.courses.isEmpty) {
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
      padding: const EdgeInsets.all(AppSpacing.medium),
      itemCount: provider.courses.length,
      itemBuilder: (context, index) {
        final course = provider.courses[index];
        return _buildCourseCard(course, provider);
      },
    );
  }

  Widget _buildCourseCard(CourseModel course, CourseProvider provider) {
    final statusColor = course.isActive ? Colors.green : AppColors.textMuted;
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
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                tooltip: 'تعديل',
                onPressed: () {
                  provider.selectCourse(course);
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.adminEditCourse, arguments: course);
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  Icons.archive_rounded,
                  color: course.isArchived
                      ? AppColors.textDisabled
                      : AppColors.secondary,
                ),
                tooltip: 'أرشفة',
                onPressed: course.isArchived
                    ? null
                    : () => _showArchiveDialog(context, course),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.danger,
                ),
                tooltip: 'حذف',
                onPressed: () => _showDeleteDialog(context, course),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
