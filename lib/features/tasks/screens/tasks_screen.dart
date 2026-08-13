import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:academia/core/navigation/main_navigation.dart';
import 'package:academia/core/theme/app_colors.dart';
import 'package:academia/core/theme/app_spacing.dart';
import 'package:academia/core/widgets/app_bottom_navigation.dart';
import 'package:academia/core/widgets/app_loading_state.dart';
import 'package:academia/core/widgets/authenticated_page_scaffold.dart';
import 'package:academia/core/widgets/empty_state.dart';
import 'package:academia/core/widgets/error_state.dart';
import 'package:academia/core/widgets/app_top_bar.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';
import 'package:academia/features/tasks/widgets/filter_bottom_sheet.dart';
import 'package:academia/features/tasks/widgets/task_card.dart';
import 'package:academia/features/tasks/widgets/task_filter_bar.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskQuickFilter quickFilter = TaskQuickFilter.all;
  TaskFilter advancedFilter = const TaskFilter();

  List<TaskModel> _applyFilters(List<TaskModel> tasks) {
    Iterable<TaskModel> result = tasks;

    // Apply quick filter
    switch (quickFilter) {
      case TaskQuickFilter.all:
        break;
      case TaskQuickFilter.today:
        result = result.where((task) => !task.isCompleted && task.isToday());
        break;
      case TaskQuickFilter.overdue:
        result = result.where((task) => !task.isCompleted && task.isOverdue());
        break;
      case TaskQuickFilter.upcoming:
        result = result.where((task) => !task.isCompleted && task.isUpcoming());
        break;
      case TaskQuickFilter.completed:
        result = result.where((task) => task.isCompleted);
        break;
    }

    // Apply advanced filters
    if (advancedFilter.status != null) {
      result = result.where((task) => task.status == advancedFilter.status);
    }
    if (advancedFilter.priority != null) {
      result = result.where((task) => task.priority == advancedFilter.priority);
    }
    if (advancedFilter.enrollmentId != null) {
      result = result.where((task) => task.enrollmentId == advancedFilter.enrollmentId);
    }

    return result.toList();
  }

  Future<void> _openAdvancedFilter(List<StudentCourseView> currentCourses) async {
    final selected = await showTaskFilterBottomSheet(
      context,
      currentFilter: advancedFilter,
      currentCourses: currentCourses,
    );
    if (selected != null) {
      setState(() => advancedFilter = selected);
    }
  }

  void _clearAllFilters() {
    setState(() {
      quickFilter = TaskQuickFilter.all;
      advancedFilter = const TaskFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final studentCourses = context.watch<StudentCoursesProvider>();

    Widget body;

    if (taskProvider.isLoading) {
      body = const AppLoadingState(message: 'جاري تحميل المهام الدراسية...');
    } else if (taskProvider.errorMessage != null) {
      body = AppErrorState(
        message: taskProvider.errorMessage!,
        onRetry: () {
          final auth = context.read<AuthProvider>();
          if (auth.isLoggedIn && auth.currentUserProfile != null) {
            taskProvider.syncWithUserAndCourses(
              userId: auth.currentUser?.uid,
              isLoggedIn: auth.isLoggedIn,
              currentCourses: studentCourses.currentCourses,
            );
          }
        },
      );
    } else if (taskProvider.tasks.isEmpty) {
      body = AppEmptyState(
        title: 'لا توجد مهام دراسية',
        description: 'لا توجد لديكِ أي مهام دراسية حالياً. أضيفي مهامكِ لتنظيم وقتكِ الدراسي.',
        icon: Icons.assignment_outlined,
        actionLabel: 'إضافة مهمة جديدة',
        onAction: () => Navigator.of(context).pushNamed('/tasks/create-edit'),
      );
    } else {
      final filteredTasks = _applyFilters(taskProvider.tasks);
      final overdueCount = taskProvider.tasks.where((t) => !t.isCompleted && t.isOverdue()).length;

      body = Column(
        children: [
          const SizedBox(height: AppSpacing.medium),
          TaskFilterBar(
            selected: quickFilter,
            onChanged: (value) => setState(() => quickFilter = value),
            overdueCount: overdueCount,
            onOpenAdvancedFilter: () => _openAdvancedFilter(studentCourses.currentCourses),
          ),
          const SizedBox(height: AppSpacing.medium),
          Expanded(
            child: filteredTasks.isEmpty
                ? AppEmptyState(
                    title: 'لا توجد نتائج',
                    description: 'لا توجد مهام تطابق خيارات التصفية المحددة.',
                    icon: Icons.filter_list_off_rounded,
                    actionLabel: 'مسح الفلاتر',
                    onAction: _clearAllFilters,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return TaskCard(
                        key: ValueKey(task.id),
                        task: task,
                        onTap: () => Navigator.of(context).pushNamed(
                          '/tasks/detail',
                          arguments: task.id,
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return AuthenticatedPageScaffold(
      currentIndex: AcademiaBottomNavigation.tasksIndex,
      onNavigationTap: (index) {
        handleMainNavigation(
          context,
          index,
          currentIndex: AcademiaBottomNavigation.tasksIndex,
        );
      },
      appBar: const AcademiaMainAppBar(
        title: 'المهام والواجبات',
        showSearch: false,
        showNotifications: false,
        showProfile: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/tasks/create-edit'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: body,
    );
  }
}
