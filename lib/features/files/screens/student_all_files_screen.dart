// lib/features/files/screens/student_all_files_screen.dart

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
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/error_state.dart';
import '../../courses/providers/student_courses_provider.dart';
import '../models/course_file_model.dart';
import '../providers/course_file_provider.dart';
import '../widgets/student_all_file_card.dart';
import '../widgets/student_file_filter_tabs.dart';
import 'student_file_preview_screen.dart';

/// كل ملفات الطالب عبر الطروح المصرَّح له بها.
///
/// التصميم كما وضعه فريق الواجهة. ما تغيّر هو المصدر: لا بيانات وهمية، بل
/// ملفات حقيقية من Firestore.
///
/// الطروح المصرَّح بها تأتي من تسجيلات الطالب نفسها — الحالية والسابقة —
/// ولكل طرح استعلام مقيَّد به. لا يوجد استعلام عام على courseFiles: القاعدة
/// ترفضه، ومحاولته تُفشل الشاشة كلها.
class AllFilesScreen extends StatefulWidget {
  const AllFilesScreen({super.key});

  @override
  State<AllFilesScreen> createState() => _AllFilesScreenState();
}

class _AllFilesScreenState extends State<AllFilesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = FileFilterTabs.filterAll;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
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

  /// التنزيل غير المتصل مؤجَّل. لا نعرض بيانات تنزيل وهمية ولا شاشة فارغة
  /// تدّعي أنها تعمل.
  void _showOfflineDeferred() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.screenUnderDevelopment),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openPreview(CourseFileModel file, String subjectLabel) {
    Navigator.pushNamed(
      context,
      AppRoutes.filePreview,
      arguments: FilePreviewArgs(file: file, subjectLabel: subjectLabel),
    );
  }

  /// معرّفات الطروح التي يملك الطالب حق قراءتها.
  ///
  /// [StudentCoursesProvider] يستبعد التسجيلات المُزالة من القائمتين، فلا
  /// ينتج عنها معرّف طرح أصلًا.
  List<String> _authorizedOfferingIds(StudentCoursesProvider courses) {
    return <String>{
      for (final view in courses.currentCourses)
        if (view.offeringId.isNotEmpty) view.offeringId,
      for (final view in courses.history)
        if (view.offeringId.isNotEmpty) view.offeringId,
    }.toList();
  }

  List<CourseFileModel> _applyFilters(List<CourseFileModel> files) {
    var result = files;

    if (_selectedFilter == FileFilterTabs.filterPdf) {
      result = result
          .where((file) => file.typeGroup == CourseFileModel.typePdf)
          .toList();
    } else if (_selectedFilter == FileFilterTabs.filterPresentations) {
      result = result
          .where((file) => file.typeGroup == CourseFileModel.typePpt)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((file) => file.title.toLowerCase().contains(query))
          .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<StudentCoursesProvider>();
    final fileProvider = context.watch<CourseFileProvider>();

    final offeringIds = _authorizedOfferingIds(courses);

    // يُعاد ضبط المستمعين فقط عند تغيّر مجموعة الطروح المصرَّح بها.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseFileProvider>().listenToOfferingsFiles(offeringIds);
    });

    if (courses.isLoading && !courses.hasLoaded) {
      return _buildScaffold(body: const AppLoadingState());
    }

    if (fileProvider.isLoading && fileProvider.files.isEmpty) {
      return _buildScaffold(body: const AppLoadingState());
    }

    if (fileProvider.errorMessage != null && fileProvider.files.isEmpty) {
      return _buildScaffold(
        body: AppErrorState(
          message: fileProvider.errorMessage!,
          onRetry: () {
            final provider = context.read<CourseFileProvider>();
            provider.stopListening();
            provider.listenToOfferingsFiles(offeringIds);
          },
        ),
      );
    }

    final visible = _applyFilters(fileProvider.activeFiles);

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
              Text(
                AppStrings.allFilesTitle,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.medium),
              _buildSearchField(),
              const SizedBox(height: AppSpacing.medium),
              FileFilterTabs(
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  setState(() => _selectedFilter = filter);
                },
                onOfflineTap: _showOfflineDeferred,
              ),
              const SizedBox(height: AppSpacing.medium),
              if (visible.isEmpty)
                _buildEmptyState(offeringIds.isEmpty)
              else
                ...visible.map((file) {
                  final subject =
                      courses.courseById(file.courseId)?.title ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: AllFileCard(
                      file: file,
                      subjectLabel: subject,
                      onTap: () => _openPreview(file, subject),
                    ),
                  );
                }),
              const SizedBox(height: AppSpacing.large),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold({required Widget body}) {
    return AuthenticatedPageScaffold(
      currentIndex: AcademiaBottomNavigation.coursesIndex,
      onNavigationTap: _handleNavigation,
      appBar: const AcademiaMainAppBar(
        title: AppStrings.appName,
        showBackButton: true,
        showProfile: false,
        showSearch: false,
        showNotifications: false,
      ),
      body: body,
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textAlign: TextAlign.right,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: AppStrings.allFilesSearchHint,
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

  /// "لا مساقات مسجَّلة" ليست نفسها "لا ملفات": الأولى تعني ألا مصدر أصلًا.
  Widget _buildEmptyState(bool hasNoOfferings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.extraLarge),
      child: Center(
        child: Text(
          hasNoOfferings
              ? AppStrings.noEnrolledCoursesForFiles
              : AppStrings.noFilesFoundMessage,
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
