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
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/student_course_view.dart';
import '../providers/student_courses_provider.dart';
import '../widgets/student_attempt_card.dart';
import '../widgets/student_available_course_card.dart';
import '../widgets/student_course_card.dart';
import '../widgets/student_course_status_tabs.dart';
import '../widgets/student_program_entry_card.dart';
import 'student_course_detail_screen.dart';

/// شاشة مساقات الطالب.
///
/// أربعة أقسام مبنية على مصدر واحد: برنامجي (الخطة) والمتاح الآن (تقاطع
/// الخطة مع طروحات الفصل) والحالية والسجل (التسجيلات). القسم الأول وحده
/// لا يعتمد على التسجيل إطلاقًا، لذلك يظل مفيدًا لطالب لم يُسجَّل بعد.
class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final TextEditingController _searchController = TextEditingController();

  StudentCoursesTab _selectedTab = StudentCoursesTab.program;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // لا يوجد load() هنا: ربط AuthProvider يقود التحميل تلقائيًا.
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query == _searchQuery) return;
      setState(() => _searchQuery = query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    handleMainNavigation(
      context,
      index,
      currentIndex: AcademiaBottomNavigation.coursesIndex,
    );
  }

  void _retry() {
    final user = context.read<AuthProvider>().currentUserProfile;
    if (user == null) return;
    context.read<StudentCoursesProvider>().load(user: user);
  }

  void _openCourseDetail({required String courseId, String? offeringId}) {
    Navigator.pushNamed(
      context,
      AppRoutes.courseDetail,
      arguments: StudentCourseDetailArgs(
        courseId: courseId,
        offeringId: offeringId,
      ),
    );
  }

  bool _matchesSearch(String code, String title) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return title.toLowerCase().contains(query) ||
        code.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentCoursesProvider>();

    return AuthenticatedPageScaffold(
      currentIndex: AcademiaBottomNavigation.coursesIndex,
      onNavigationTap: _handleNavigation,
      appBar: const AcademiaMainAppBar(
        title: AppStrings.appName,
        showProfile: true,
        showSearch: false,
        showNotifications: true,
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(StudentCoursesProvider provider) {
    if (provider.isLoading && !provider.hasLoaded) {
      return const AppLoadingState();
    }

    // خطأ تحميل حقيقي — يختلف عن قسم فارغ بشكل مشروع.
    if (provider.errorMessage != null && !provider.hasLoaded) {
      return AppErrorState(message: provider.errorMessage!, onRetry: _retry);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.screenVertical,
            AppSpacing.screenHorizontal,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.myCoursesTitle,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.medium),
              _buildSearchField(),
              const SizedBox(height: AppSpacing.medium),
              CourseStatusTabs(
                selected: _selectedTab,
                onChanged: (tab) => setState(() => _selectedTab = tab),
                labels: const {
                  StudentCoursesTab.program: AppStrings.studentTabProgram,
                  StudentCoursesTab.availableNow:
                      AppStrings.studentTabAvailableNow,
                  StudentCoursesTab.current: AppStrings.studentTabCurrent,
                  StudentCoursesTab.history: AppStrings.studentTabHistory,
                },
              ),
            ],
          ),
        ),
        Expanded(child: _buildTabContent(provider)),
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

  Widget _buildTabContent(StudentCoursesProvider provider) {
    switch (_selectedTab) {
      case StudentCoursesTab.program:
        return _buildProgram(provider);
      case StudentCoursesTab.availableNow:
        return _buildAvailableNow(provider);
      case StudentCoursesTab.current:
        return _buildCurrentCourses(provider);
      case StudentCoursesTab.history:
        return _buildHistory(provider);
    }
  }

  EdgeInsets get _listPadding => const EdgeInsets.fromLTRB(
    AppSpacing.screenHorizontal,
    AppSpacing.medium,
    AppSpacing.screenHorizontal,
    AppSpacing.huge,
  );

  // -------------------------------------------------------------- برنامجي

  Widget _buildProgram(StudentCoursesProvider provider) {
    // غياب البرنامج الأكاديمي حالة مختلفة عن خطة فارغة، ولها إجراء مختلف.
    if (!provider.hasMajor) {
      return const AppEmptyState(
        title: AppStrings.noMajorTitle,
        description: AppStrings.noMajorDesc,
        icon: Icons.school_outlined,
      );
    }

    final levels = provider.programLevels;
    if (levels.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.programEmptyTitle,
        description: AppStrings.programEmptyDesc,
        icon: Icons.list_alt_rounded,
      );
    }

    final totalRows = provider.programByLevel.values.fold<int>(
      0,
      (sum, rows) => sum + rows.length,
    );

    return ListView(
      padding: _listPadding,
      children: [
        _buildProgramSummary(totalRows, provider.programTotalCreditHours),
        for (final level in levels) ...[
          StudentProgramLevelHeader(
            level: level,
            creditHours: provider
                .programForLevel(level)
                .fold<int>(0, (sum, row) => sum + row.creditHours),
          ),
          ...provider
              .programForLevel(level)
              .where((row) => _matchesSearch(row.courseCode, row.title))
              .map(
                (row) => StudentProgramEntryCard(
                  entry: row,
                  // الخانات ليست مساقات: البطاقة نفسها تتجاهل onTap لها.
                  onTap: row.isSlot
                      ? null
                      : () => _openCourseDetail(
                          courseId: row.entry.courseId ?? '',
                        ),
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildProgramSummary(int rowCount, int totalHours) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              Icons.list_alt_rounded,
              AppStrings.programRowsLabel,
              '$rowCount',
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.divider),
          Expanded(
            child: _buildSummaryItem(
              Icons.hourglass_bottom_rounded,
              AppStrings.programTotalHoursLabel,
              '$totalHours',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.secondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // --------------------------------------------------------- المتاحة الآن

  Widget _buildAvailableNow(StudentCoursesProvider provider) {
    if (!provider.hasCurrentSemester) {
      return const AppEmptyState(
        title: AppStrings.noCurrentSemesterTitle,
        description: AppStrings.noCurrentSemesterDesc,
        icon: Icons.event_busy_rounded,
      );
    }

    if (!provider.hasMajor) {
      return const AppEmptyState(
        title: AppStrings.noMajorTitle,
        description: AppStrings.noMajorDesc,
        icon: Icons.school_outlined,
      );
    }

    final rows = provider.availableNow
        .where((view) => _matchesSearch(view.courseCode, view.title))
        .toList();

    // فراغ مشروع لا خطأ: قد لا يُطرح أي مساق من الخطة هذا الفصل.
    if (rows.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.availableNowEmptyTitle,
        description: AppStrings.availableNowEmptyDesc,
        icon: Icons.event_available_outlined,
      );
    }

    return ListView.builder(
      padding: _listPadding,
      itemCount: rows.length,
      itemBuilder: (context, index) => StudentAvailableCourseCard(
        view: rows[index],
        onTap: () => _openCourseDetail(
          courseId: rows[index].courseId,
          offeringId: rows[index].offeringId,
        ),
      ),
    );
  }

  // ----------------------------------------------------- مساقاتي الحالية

  Widget _buildCurrentCourses(StudentCoursesProvider provider) {
    if (!provider.hasCurrentSemester) {
      return const AppEmptyState(
        title: AppStrings.noCurrentSemesterTitle,
        description: AppStrings.noCurrentSemesterDesc,
        icon: Icons.event_busy_rounded,
      );
    }

    final rows = provider.currentCourses
        .where((view) => _matchesSearch(view.courseCode, view.title))
        .toList();

    if (rows.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.currentCoursesEmptyTitle,
        description: AppStrings.currentCoursesEmptyDesc,
        icon: Icons.menu_book_outlined,
      );
    }

    return ListView.builder(
      padding: _listPadding,
      itemCount: rows.length,
      itemBuilder: (context, index) => StudentCourseCard(
        view: rows[index],
        onTap: () => _openCourseDetail(
          courseId: rows[index].courseId,
          offeringId: rows[index].offeringId,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- السجل

  Widget _buildHistory(StudentCoursesProvider provider) {
    final grouped = provider.historyByCourse;

    if (grouped.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.historyEmptyTitle,
        description: AppStrings.historyEmptyDesc,
        icon: Icons.history_rounded,
      );
    }

    final courseIds = grouped.keys.where((courseId) {
      final first = grouped[courseId]!.first;
      return _matchesSearch(first.courseCode, first.title);
    }).toList();

    return ListView(
      padding: _listPadding,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.coursesArchive);
            },
            icon: const Icon(Icons.open_in_full_rounded, size: 16),
            label: const Text(AppStrings.viewFullArchiveAction),
          ),
        ),
        for (final courseId in courseIds)
          ..._buildHistoryGroup(grouped[courseId]!),
      ],
    );
  }

  List<Widget> _buildHistoryGroup(List<StudentCourseView> attempts) {
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
      // كل محاولة بطاقة مستقلة: إعادة الدراسة ليست تحديثًا لمحاولة سابقة.
      ...attempts.map(
        (attempt) => StudentAttemptCard(
          view: attempt,
          onTap: () => _openCourseDetail(
            courseId: attempt.courseId,
            offeringId: attempt.offeringId,
          ),
        ),
      ),
    ];
  }
}
