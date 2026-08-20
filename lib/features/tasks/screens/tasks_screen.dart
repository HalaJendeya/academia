import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../assignments/models/course_assignment_model.dart';
import '../../assignments/providers/course_assignment_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../courses/models/student_course_view.dart';
import '../../courses/providers/student_courses_provider.dart';
import '../../courses/widgets/student_assignment_preview_card.dart';
import '../models/student_work_item.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_bar.dart';

/// شاشة الطالب الموحَّدة: «المهام والواجبات».
///
/// تجمع مصدرين مستقلين تمامًا في العرض فقط:
///
///   /tasks       → مهام شخصية ينشئها الطالب      → [TaskProvider]
///   /assignments → واجبات أكاديمية يفرضها المعلّم → [CourseAssignmentProvider]
///
/// المجموعتان لا تُدمجان في Firestore ولا تُنسخ إحداهما إلى الأخرى: ملكيتهما
/// وصلاحياتهما مختلفتان جذريًا. الدمج يحدث في الذاكرة عبر [StudentWorkItem]
/// لحظة البناء.
///
/// اشتراك الواجبات لا يُدار هنا: ProxyProvider في app_providers يغذّي
/// المزوّد بطروح الطالب الحالية، فتكون البيانات جاهزة للوحة اليوم ولهذه
/// الشاشة معًا دون أن يعتمد أحدهما على فتح الآخر.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

enum _WorkTab { all, assignments, myTasks, completed }

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// المرشِّحات الزمنية والمتقدمة تخص تبويب «مهامي» وحده.
  ///
  /// فرضها على الواجبات كان سيعني إسقاط مفاهيم المهمة الشخصية — الحالة
  /// والتسجيل المرتبط — على نموذج لا يملكها.
  TaskQuickFilter _quickFilter = TaskQuickFilter.all;
  TaskFilter _advancedFilter = const TaskFilter();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _WorkTab.values.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- personal

  List<TaskModel> _pendingTasks(List<TaskModel> tasks) =>
      tasks.where((task) => task.isPending).toList();

  List<TaskModel> _completedTasks(List<TaskModel> tasks) =>
      tasks.where((task) => task.isCompleted).toList();

  /// مرشِّحات تبويب «مهامي» فقط.
  List<TaskModel> _applyTaskFilters(List<TaskModel> tasks) {
    Iterable<TaskModel> result = tasks;

    switch (_quickFilter) {
      case TaskQuickFilter.all:
        break;
      case TaskQuickFilter.today:
        result = result.where((task) => task.isToday());
        break;
      case TaskQuickFilter.overdue:
        result = result.where((task) => task.isOverdue());
        break;
      case TaskQuickFilter.upcoming:
        result = result.where((task) => task.isUpcoming());
        break;
      case TaskQuickFilter.completed:
        // للتبويب المكتمل شاشته الخاصة؛ لا يُختار هنا.
        break;
    }

    if (_advancedFilter.status != null) {
      result = result.where((task) => task.status == _advancedFilter.status);
    }
    if (_advancedFilter.priority != null) {
      result = result.where((task) => task.priority == _advancedFilter.priority);
    }
    if (_advancedFilter.enrollmentId != null) {
      result = result.where(
        (task) => task.enrollmentId == _advancedFilter.enrollmentId,
      );
    }

    return result.toList();
  }

  Future<void> _openAdvancedFilter(
    List<StudentCourseView> currentCourses,
  ) async {
    final selected = await showTaskFilterBottomSheet(
      context,
      currentFilter: _advancedFilter,
      currentCourses: currentCourses,
    );
    if (selected != null && mounted) {
      setState(() => _advancedFilter = selected);
    }
  }

  void _clearTaskFilters() {
    setState(() {
      _quickFilter = TaskQuickFilter.all;
      _advancedFilter = const TaskFilter();
    });
  }

  void _retryTasks() {
    final auth = context.read<AuthProvider>();
    final studentCourses = context.read<StudentCoursesProvider>();
    if (!auth.isLoggedIn) return;

    context.read<TaskProvider>().syncWithUserAndCourses(
      userId: auth.currentUser?.uid,
      isLoggedIn: auth.isLoggedIn,
      currentCourses: studentCourses.currentCourses,
    );
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final assignmentProvider = context.watch<CourseAssignmentProvider>();
    final studentCourses = context.watch<StudentCoursesProvider>();

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
        title: AppStrings.tasksAndAssignmentsTitle,
        showSearch: false,
        showNotifications: false,
        showProfile: false,
      ),
      /*
       * الإضافة تخص المهام الشخصية وحدها: الطالب لا يؤلّف واجبات أكاديمية.
       * لذلك يختفي الزر في تبويب الواجبات بدل أن يَعِد بفعل مرفوض.
       */
      floatingActionButton: _currentTab == _WorkTab.assignments
          ? null
          : FloatingActionButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.createEditTask),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded, size: 28),
            ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTab(taskProvider, assignmentProvider),
                _buildAssignmentsTab(assignmentProvider),
                _buildMyTasksTab(taskProvider, studentCourses),
                _buildCompletedTab(taskProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _WorkTab get _currentTab => _WorkTab.values[_tabController.index];

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        // قابل للتمرير: أربع تسميات عربية لا تتسع بثبات على عرض 360.
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        tabs: const [
          Tab(text: AppStrings.workTabAll),
          Tab(text: AppStrings.workTabAssignments),
          Tab(text: AppStrings.workTabMyTasks),
          Tab(text: AppStrings.workTabCompleted),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- الكل tab

  Widget _buildAllTab(
    TaskProvider taskProvider,
    CourseAssignmentProvider assignmentProvider,
  ) {
    final tasksLoading = taskProvider.isLoading;
    final assignmentsLoading = assignmentProvider.isLoading;

    final tasksFailed = taskProvider.errorMessage != null;
    final assignmentsFailed = assignmentProvider.errorMessage != null;

    /*
     * لا نُعلن «لا شيء عليك» قبل أن يفرغ المصدران.
     *
     * لو اكتفينا بجاهزية المهام لظهرت الشاشة فارغة بينما الواجبات ما تزال
     * قادمة — وهو أسوأ من الانتظار: إخبار الطالب أن لا واجب عليه وهو عليه.
     */
    if (tasksLoading || assignmentsLoading) {
      return const AppLoadingState();
    }

    // فشل المصدرين معًا: لا شيء يُعرض، فالخطأ هو المحتوى.
    if (tasksFailed && assignmentsFailed) {
      return AppErrorState(
        title: AppStrings.workAllErrorTitle,
        message: taskProvider.errorMessage!,
        onRetry: _retryTasks,
      );
    }

    final items = StudentWorkItem.merge(
      tasks: tasksFailed ? const <TaskModel>[] : taskProvider.tasks,
      assignments: assignmentsFailed
          ? const <CourseAssignmentModel>[]
          : assignmentProvider.activeAssignments,
    );

    // فشل أحدهما فقط: يبقى المتاح معروضًا مع تنبيه، لا شاشة خطأ كاملة.
    final notice = tasksFailed
        ? AppStrings.workTasksUnavailableNote
        : (assignmentsFailed ? AppStrings.workAssignmentsUnavailableNote : null);

    if (items.isEmpty) {
      return _withNotice(
        notice,
        const AppEmptyState(
          title: AppStrings.workEmptyAllTitle,
          description: AppStrings.workEmptyAllDesc,
          icon: Icons.checklist_rtl_rounded,
        ),
      );
    }

    return _withNotice(
      notice,
      ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.medium,
          AppSpacing.medium,
          AppSpacing.medium,
          AppSpacing.huge,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildWorkItem(items[index]),
      ),
    );
  }

  /// عنصر واحد في القائمة المدموجة، بالبطاقة التي تخص نوعه.
  ///
  /// المهمة الشخصية تحتفظ ببطاقتها الكاملة بأفعالها — إكمال وتعديل وحذف —
  /// والواجب يُعرض ببطاقة القراءة نفسها المستعملة في تفاصيل المساق.
  Widget _buildWorkItem(StudentWorkItem item) {
    if (item.isPersonalTask) {
      final task = item.task!;
      return TaskCard(
        key: ValueKey(item.id),
        task: task,
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRoutes.taskDetail, arguments: task.id),
      );
    }

    return Padding(
      key: ValueKey(item.id),
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: AssignmentPreviewCard(assignment: item.assignment!),
    );
  }

  /// تنبيه علوي اختياري فوق محتوى ما يزال صالحًا.
  Widget _withNotice(String? notice, Widget child) {
    if (notice == null) return child;

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.medium,
            AppSpacing.medium,
            AppSpacing.medium,
            0,
          ),
          padding: const EdgeInsets.all(AppSpacing.small),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            notice,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.warningDark,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  // --------------------------------------------------------- الواجبات tab

  Widget _buildAssignmentsTab(CourseAssignmentProvider provider) {
    if (provider.isLoading && provider.assignments.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.assignments.isEmpty) {
      return AppErrorState(
        title: AppStrings.workAssignmentsErrorTitle,
        message: provider.errorMessage!,
      );
    }

    final assignments = provider.activeAssignments;

    if (assignments.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.workEmptyAssignmentsTitle,
        description: AppStrings.workEmptyAssignmentsDesc,
        icon: Icons.assignment_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.huge,
      ),
      itemCount: assignments.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.small),
        // للقراءة فقط: لا إنشاء ولا تعديل ولا أرشفة للطالب.
        child: AssignmentPreviewCard(assignment: assignments[index]),
      ),
    );
  }

  // ----------------------------------------------------------- مهامي tab

  Widget _buildMyTasksTab(
    TaskProvider taskProvider,
    StudentCoursesProvider studentCourses,
  ) {
    if (taskProvider.isLoading) return const AppLoadingState();

    if (taskProvider.errorMessage != null) {
      return AppErrorState(
        title: AppStrings.workTasksErrorTitle,
        message: taskProvider.errorMessage!,
        onRetry: _retryTasks,
      );
    }

    final pending = _pendingTasks(taskProvider.tasks);

    if (pending.isEmpty) {
      return AppEmptyState(
        title: AppStrings.workEmptyMyTasksTitle,
        description: AppStrings.workEmptyMyTasksDesc,
        icon: Icons.checklist_rounded,
        actionLabel: AppStrings.addNewTaskAction,
        onAction: () =>
            Navigator.of(context).pushNamed(AppRoutes.createEditTask),
      );
    }

    final filtered = _applyTaskFilters(pending);
    final overdueCount = pending.where((task) => task.isOverdue()).length;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.medium),
        TaskFilterBar(
          selected: _quickFilter,
          onChanged: (value) => setState(() => _quickFilter = value),
          overdueCount: overdueCount,
          onOpenAdvancedFilter: () =>
              _openAdvancedFilter(studentCourses.currentCourses),
          /*
           * صف واحد أسفل التبويبات، وفي تبويب «مهامي» وحده.
           *
           * «مكتملة» غائبة لأن لها تبويبًا مستقلًا. و«الكل» هنا تعني «كل
           * مهامي المعلَّقة» داخل هذا التبويب، لا تبويب «الكل» الذي يجمع
           * المصدرين — ولذلك تأتي بعد المرشِّحات الزمنية لا قبلها.
           */
          visibleFilters: const [
            TaskQuickFilter.today,
            TaskQuickFilter.overdue,
            TaskQuickFilter.upcoming,
            TaskQuickFilter.all,
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        Expanded(
          child: filtered.isEmpty
              ? AppEmptyState(
                  title: AppStrings.noSearchResultsTitle,
                  description: AppStrings.noFilterResultsDesc,
                  icon: Icons.filter_list_off_rounded,
                  actionLabel: AppStrings.clearFiltersAction,
                  onAction: _clearTaskFilters,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.medium,
                    0,
                    AppSpacing.medium,
                    AppSpacing.huge,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return TaskCard(
                      key: ValueKey(task.id),
                      task: task,
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.taskDetail, arguments: task.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --------------------------------------------------------- مكتملة tab

  /*
   * المهام الشخصية المكتملة وحدها.
   *
   * 🔴 قيد منتج لا إغفال: لا يوجد نموذج تسليم أو إنجاز للواجب الأكاديمي
   * لكل طالب. حالة الواجب في Firestore عامة (active/archived) ويكتبها
   * المعلّم للجميع، فلا يمكن اشتقاق «أنهى هذا الطالب هذا الواجب». عرض
   * واجبات هنا كان سيتطلب اختلاق حالة إنجاز لا وجود لها.
   */
  Widget _buildCompletedTab(TaskProvider taskProvider) {
    if (taskProvider.isLoading) return const AppLoadingState();

    if (taskProvider.errorMessage != null) {
      return AppErrorState(
        title: AppStrings.workTasksErrorTitle,
        message: taskProvider.errorMessage!,
        onRetry: _retryTasks,
      );
    }

    final completed = _completedTasks(taskProvider.tasks)
      ..sort((a, b) {
        // الأحدث إنجازًا أولًا؛ ما لا تاريخ لإنجازه يتبع بترتيب ثابت.
        final aDone = a.completedAt;
        final bDone = b.completedAt;
        if (aDone != null && bDone != null) return bDone.compareTo(aDone);
        if (aDone != null) return -1;
        if (bDone != null) return 1;
        return a.id.compareTo(b.id);
      });

    if (completed.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.workEmptyCompletedTitle,
        description: AppStrings.workEmptyCompletedDesc,
        icon: Icons.task_alt_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.huge,
      ),
      itemCount: completed.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.medium),
            child: Text(
              AppStrings.workCompletedTasksOnlyNote,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.right,
            ),
          );
        }

        final task = completed[index - 1];
        return TaskCard(
          key: ValueKey(task.id),
          task: task,
          onTap: () => Navigator.of(
            context,
          ).pushNamed(AppRoutes.taskDetail, arguments: task.id),
        );
      },
    );
  }
}
