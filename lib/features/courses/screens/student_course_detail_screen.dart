import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../files/services/course_file_opener.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../curriculum/models/curriculum_course_model.dart';
import '../../assignments/providers/course_assignment_provider.dart';
import '../widgets/student_assignment_preview_card.dart';
import '../../files/models/course_file_model.dart';
import '../../files/providers/course_file_provider.dart';
import '../widgets/student_file_list_item_card.dart';
import '../models/course_model.dart';
import '../models/student_course_view.dart';
import '../providers/student_courses_provider.dart';
import '../widgets/student_course_header_card.dart';

/// وسيطات شاشة التفاصيل.
///
/// [offeringId] هو ما يفرّق السياقين: مساق من الخطة (بلا طرح) أو محاولة
/// فعلية للطالب في طرح محدد.
class StudentCourseDetailArgs {
  const StudentCourseDetailArgs({required this.courseId, this.offeringId});

  final String courseId;
  final String? offeringId;
}

/// تفاصيل مساق للطالب.
///
/// التبويبات محفوظة كما صمّمها فريق الواجهة. الواجبات والملفات تقرآن من
/// Firestore مقيَّدتين بالطرح الذي يملك الطالب تسجيلًا فيه؛ «المساحة
/// المشتركة» وحدها تبقى تعرض حالة «غير متاح بعد» صريحة، إذ لا مجموعة
/// تغذّيها، وملؤها بقيم وهمية يجعل الشاشة تكذب على الطالب.
class StudentCourseDetailScreen extends StatelessWidget {
  const StudentCourseDetailScreen({super.key});

  void _handleNavigation(BuildContext context, int index) {
    handleMainNavigation(
      context,
      index,
      currentIndex: AcademiaBottomNavigation.coursesIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments
            as StudentCourseDetailArgs?;
    final provider = context.watch<StudentCoursesProvider>();

    final course = provider.courseById(args?.courseId);

    if (args == null || course == null) {
      return _scaffold(
        context,
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Text(
              AppStrings.courseNotFoundStudent,
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // سياق المحاولة: يوجد تسجيل للطالب في هذا الطرح تحديدًا.
    StudentCourseView? attempt;
    if (args.offeringId != null) {
      for (final view in [...provider.currentCourses, ...provider.history]) {
        if (view.offeringId == args.offeringId) {
          attempt = view;
          break;
        }
      }
    }

    final curriculumEntry = provider.curriculumEntryForCourse(args.courseId);
    final offering = provider.offeringById(args.offeringId);

    return _scaffold(
      context,
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverviewTab(
                    course: course,
                    attempt: attempt,
                    instructorName: attempt?.instructorName ??
                        offering?.instructorName,
                    curriculumEntry: curriculumEntry,
                  ),
                  // الواجبات: مقيَّدة بالطرح نفسه — الخطة وحدها لا تكفي.
                  _CourseAssignmentsTab(offeringId: args.offeringId),
                  // الملفات: مقيَّدة بالطرح الذي يملك الطالب تسجيلًا فيه.
                  _CourseFilesTab(offeringId: args.offeringId),
                  _buildNotAvailableTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scaffold(BuildContext context, {required Widget body}) {
    return AuthenticatedPageScaffold(
      currentIndex: AcademiaBottomNavigation.coursesIndex,
      onNavigationTap: (index) => _handleNavigation(context, index),
      appBar: const AcademiaSubAppBar(
        title: AppStrings.courseDetailAppBarTitle,
      ),
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

  Widget _buildNotAvailableTab() {
    return const AppEmptyState(
      title: AppStrings.featureNotAvailableYetTitle,
      description: AppStrings.featureNotAvailableYetDesc,
      icon: Icons.hourglass_empty_rounded,
    );
  }

  Widget _buildOverviewTab({
    required CourseModel course,
    required StudentCourseView? attempt,
    required String? instructorName,
    required CurriculumCourseModel? curriculumEntry,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudentCourseHeaderCard(
            course: course,
            instructorName: instructorName,
          ),
          if (course.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.medium),
            AppCard(
              child: Text(
                course.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
          if (curriculumEntry != null) ...[
            const SizedBox(height: AppSpacing.medium),
            _buildProgramSection(curriculumEntry),
          ],
          if (attempt != null) ...[
            const SizedBox(height: AppSpacing.medium),
            _buildAttemptSection(attempt),
          ],
        ],
      ),
    );
  }

  /// موقع المساق في الخطة: يظهر سواء كان الطالب مسجَّلًا فيه أم لا.
  Widget _buildProgramSection(CurriculumCourseModel entry) {
    final prerequisiteText = entry.prerequisiteText;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(AppStrings.courseProgramSectionTitle),
          const Divider(color: AppColors.divider),
          _infoRow(
            AppStrings.academicLevelLabel,
            AppStrings.academicLevelDisplay(entry.academicLevel),
          ),
          _infoRow(
            AppStrings.requirementTypeLabel,
            AppStrings.requirementTypeDisplay(entry.requirementType),
          ),
          if (prerequisiteText != null && prerequisiteText.trim().isNotEmpty)
            _infoRow(AppStrings.prerequisiteLabel, prerequisiteText)
          else
            _infoRow(AppStrings.prerequisiteLabel, AppStrings.noPrerequisite),
          const SizedBox(height: AppSpacing.extraSmall),
          Text(
            AppStrings.prerequisiteNotEnforcedNote,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  /// بيانات التسجيل: خاصة بالطرح والمحاولة، لا بالمساق الدائم.
  Widget _buildAttemptSection(StudentCourseView attempt) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(AppStrings.courseAttemptSectionTitle),
          const Divider(color: AppColors.divider),
          if (attempt.semesterName.isNotEmpty)
            _infoRow(AppStrings.courseSemesterLabel, attempt.semesterName),
          if (attempt.instructorName.isNotEmpty)
            _infoRow(AppStrings.instructorNameLabel, attempt.instructorName),
          if (attempt.section.isNotEmpty)
            _infoRow(AppStrings.sectionLabel, attempt.section),
          _infoRow(AppStrings.attemptLabel, '${attempt.attemptNumber}'),
          if (attempt.completionStatus != null)
            _infoRow(
              AppStrings.statusLabel,
              AppStrings.completionStatusDisplay(attempt.completionStatus),
            ),
          if (attempt.grade != null && attempt.grade!.trim().isNotEmpty)
            _infoRow(AppStrings.gradeLabel, attempt.grade!),
          if (attempt.isRetake) ...[
            const SizedBox(height: AppSpacing.small),
            Align(
              alignment: Alignment.centerRight,
              child: AppStatusBadge(
                label: '${AppStrings.attemptLabel} ${attempt.attemptNumber}',
                backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                foregroundColor: AppColors.warningDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.secondary,
      ),
      textAlign: TextAlign.right,
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// ملفات طرح واحد داخل تفاصيل المساق.
///
/// المسار: تسجيل الطالب ← offeringId ← courseFiles حيث offeringId يطابق.
/// بلا طرح لا ملفات: مساق من الخطة لم يُسجَّل فيه الطالب لا يملك طرحًا،
/// وقاعدة القراءة لا تمنحه شيئًا.
class _CourseFilesTab extends StatefulWidget {
  const _CourseFilesTab({required this.offeringId});

  final String? offeringId;

  @override
  State<_CourseFilesTab> createState() => _CourseFilesTabState();
}

class _CourseFilesTabState extends State<_CourseFilesTab> {
  CourseFileProvider? _fileProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fileProvider = context.read<CourseFileProvider>();

    final offeringId = widget.offeringId;
    if (offeringId == null || offeringId.trim().isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseFileProvider>().listenToOfferingFiles(offeringId);
    });
  }

  @override
  void dispose() {
    // مرجع محفوظ: لا يمكن قراءة المزوّد من context أثناء dispose.
    _fileProvider?.stopListening();
    super.dispose();
  }

  Future<void> _openFile(CourseFileModel file) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await openCourseFileUrl(file.cloudinaryUrl);
    if (!mounted || result == CourseFileOpenResult.opened) return;

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.fileOpenError)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offeringId = widget.offeringId;

    if (offeringId == null || offeringId.trim().isEmpty) {
      return const AppEmptyState(
        title: AppStrings.courseFilesNoOfferingTitle,
        description: AppStrings.courseFilesNoOfferingDesc,
        icon: Icons.folder_off_outlined,
      );
    }

    final provider = context.watch<CourseFileProvider>();

    if (provider.isLoading && provider.files.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.files.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () {
          final fileProvider = context.read<CourseFileProvider>();
          fileProvider.stopListening();
          fileProvider.listenToOfferingFiles(offeringId);
        },
      );
    }

    // النشطة وحدها: المؤرشف إزالة لا تُعرض للطالب.
    final files = provider.activeFiles;

    if (files.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.noFilesUploadedTitle,
        description: AppStrings.courseFilesEmptyDesc,
        icon: Icons.folder_open_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.small),
          child: FileListItemCard(file: file, onTap: () => _openFile(file)),
        );
      },
    );
  }
}

/// واجبات طرح واحد داخل تفاصيل المساق.
///
/// المسار: تسجيل الطالب ← offeringId ← assignments حيث offeringId يطابق.
/// بلا طرح لا واجبات: مساق من الخطة الدراسية لم يُسجَّل فيه الطالب لا يملك
/// طرحًا، ولا يجوز أن يعرض واجبات شعبةٍ ما.
///
/// للقراءة فقط: لا إنشاء ولا تعديل ولا أرشفة. المؤرشف لا يصل أصلًا لأن
/// الاستعلام يقيّد الحالة على النشط في الخادم.
class _CourseAssignmentsTab extends StatefulWidget {
  const _CourseAssignmentsTab({required this.offeringId});

  final String? offeringId;

  @override
  State<_CourseAssignmentsTab> createState() => _CourseAssignmentsTabState();
}

class _CourseAssignmentsTabState extends State<_CourseAssignmentsTab> {
  CourseAssignmentProvider? _assignmentProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assignmentProvider = context.read<CourseAssignmentProvider>();

    final offeringId = widget.offeringId;
    if (offeringId == null || offeringId.trim().isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseAssignmentProvider>().listenToOfferingAssignments(
        offeringId,
      );
    });
  }

  @override
  void dispose() {
    // مرجع محفوظ: لا يمكن قراءة المزوّد من context أثناء dispose.
    _assignmentProvider?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offeringId = widget.offeringId;

    if (offeringId == null || offeringId.trim().isEmpty) {
      return const AppEmptyState(
        title: AppStrings.courseAssignmentsNoOfferingTitle,
        description: AppStrings.courseAssignmentsNoOfferingDesc,
        icon: Icons.assignment_outlined,
      );
    }

    final provider = context.watch<CourseAssignmentProvider>();

    if (provider.isLoading && provider.assignments.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.assignments.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () {
          final assignmentProvider = context.read<CourseAssignmentProvider>();
          assignmentProvider.stopListening();
          assignmentProvider.listenToOfferingAssignments(offeringId);
        },
      );
    }

    final assignments = provider.activeAssignments;

    if (assignments.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.noAssignmentsTitle,
        description: AppStrings.courseAssignmentsEmptyDesc,
        icon: Icons.assignment_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.small),
          child: AssignmentPreviewCard(assignment: assignments[index]),
        );
      },
    );
  }
}
