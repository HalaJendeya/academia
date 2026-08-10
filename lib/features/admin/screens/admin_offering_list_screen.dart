import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../courses/models/course_model.dart';
import '../../courses/models/course_offering_model.dart';
import '../../courses/providers/course_offering_provider.dart';
import '../../courses/providers/course_provider.dart';
import '../../semesters/models/semester_model.dart';
import '../../semesters/providers/semester_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';
import 'admin_course_files_screen.dart';
import 'admin_offering_form_screen.dart';
import 'admin_offering_roster_screen.dart';

/// طروحات المساقات لفصل دراسي واحد في كل مرة.
///
/// هذه الشاشة هي ما يجعل المعمارية صالحة للتشغيل: المساق الدائم وحده لا
/// يكفي للتسجيل، والطالب يُسجَّل في طرح. بدون طرح للفصل الحالي لا يمكن
/// تسجيل أي طالب.
class AdminOfferingListScreen extends StatefulWidget {
  const AdminOfferingListScreen({super.key});

  @override
  State<AdminOfferingListScreen> createState() =>
      _AdminOfferingListScreenState();
}

class _AdminOfferingListScreenState extends State<AdminOfferingListScreen> {
  String? _selectedSemesterId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is SemesterModel) _selectedSemesterId = arguments.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SemesterProvider>().listenToSemesters();
      context.read<CourseProvider>().listenToCourses();

      // بدون فصل ممرَّر، نبدأ بالفصل الحالي: هو الفصل الذي يعمل عليه المشرف.
      final semesterId =
          _selectedSemesterId ??
          context.read<SemesterProvider>().currentSemester?.id;
      if (semesterId != null) _selectSemester(semesterId);
    });

    _initialized = true;
  }

  void _selectSemester(String semesterId) {
    if (!mounted) return;
    setState(() => _selectedSemesterId = semesterId);
    context.read<CourseOfferingProvider>().listenToSemesterOfferings(
      semesterId,
    );
  }

  void _openForm({CourseOfferingModel? offering}) {
    final semesterId = _selectedSemesterId;
    if (semesterId == null) return;

    Navigator.of(context).pushNamed(
      AppRoutes.adminAddOffering,
      arguments: OfferingFormArgs(semesterId: semesterId, offering: offering),
    );
  }

  void _showArchiveDialog(CourseOfferingModel offering, String courseTitle) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          AppStrings.archiveOfferingTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          '${AppStrings.archiveOfferingConfirm}\n($courseTitle)',
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
                Navigator.of(dialogContext).pop();

                final provider = context.read<CourseOfferingProvider>();
                final success = await provider.archiveOffering(offering.id);

                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  success
                      ? const SnackBar(
                          content: Text(AppStrings.offeringArchivedSuccess),
                        )
                      : SnackBar(
                          content: Text(
                            provider.errorMessage ??
                                AppStrings.offeringSaveError,
                          ),
                          backgroundColor: AppColors.error,
                        ),
                );
              },
              child: const Text(AppStrings.confirmAction),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancelAction),
          ),
        ],
      ),
    );
  }

  /// نسخ طروحات فصل سابق إلى الفصل المعروض.
  ///
  /// العملية متسقة عند التكرار لأن معرّفات الطروحات توليدية، فإعادة النسخ
  /// تستبدل ولا تُنشئ نسخًا مكررة.
  void _showDuplicateDialog(List<SemesterModel> semesters) {
    final target = _selectedSemesterId;
    if (target == null) return;

    final sources = semesters.where((s) => s.id != target).toList();
    if (sources.isEmpty) return;

    String? sourceId = sources.first.id;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            AppStrings.duplicateOfferingsTitle,
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                AppStrings.duplicateOfferingsDesc,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                initialValue: sourceId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.duplicateOfferingsSourceLabel,
                ),
                items: sources
                    .map(
                      (semester) => DropdownMenuItem<String>(
                        value: semester.id,
                        child: Text(
                          semester.semesterName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => sourceId = value),
              ),
            ],
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
                  final from = sourceId;
                  Navigator.of(dialogContext).pop();
                  if (from == null) return;

                  final provider = context.read<CourseOfferingProvider>();
                  final count = await provider.duplicateSemesterOfferings(
                    fromSemesterId: from,
                    toSemesterId: target,
                  );

                  if (!mounted) return;

                  if (count == null) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.errorMessage ?? AppStrings.offeringSaveError,
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  // صفر ليس خطأ، لكنه لا يعني شيئًا للمشرف ما لم يُذكر.
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        count == 0
                            ? AppStrings.duplicateOfferingsNone
                            : '${AppStrings.duplicateOfferingsSuccessPrefix} '
                                  '$count ${AppStrings.duplicateOfferingsSuccessSuffix}',
                      ),
                    ),
                  );
                },
                child: const Text(AppStrings.duplicateOfferingsConfirm),
              ),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.cancelAction),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semesterProvider = context.watch<SemesterProvider>();
    final offeringProvider = context.watch<CourseOfferingProvider>();
    final courses = context.watch<CourseProvider>().courses;
    final coursesById = {for (final course in courses) course.id: course};

    final canDuplicate =
        _selectedSemesterId != null && semesterProvider.semesters.length > 1;

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.offeringsManagementTitle),
          centerTitle: true,
          leading: const AdminBackButton(),
          actions: [
            if (canDuplicate)
              IconButton(
                tooltip: AppStrings.duplicateOfferingsAction,
                icon: const Icon(Icons.copy_all_rounded),
                onPressed: () =>
                    _showDuplicateDialog(semesterProvider.semesters),
              ),
          ],
        ),
        floatingActionButton: _selectedSemesterId == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _openForm(),
                label: const Text(AppStrings.addOfferingLabel),
                icon: const Icon(Icons.add_rounded),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: DropdownButtonFormField<String>(
                initialValue:
                    (_selectedSemesterId != null &&
                        semesterProvider.byId.containsKey(_selectedSemesterId))
                    ? _selectedSemesterId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.event_note_rounded),
                  hintText: AppStrings.courseSemesterSelectHint,
                ),
                items: semesterProvider.semesters
                    .map(
                      (semester) => DropdownMenuItem<String>(
                        value: semester.id,
                        child: Text(
                          semester.semesterName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _selectSemester(value);
                },
              ),
            ),
            Expanded(child: _buildBody(offeringProvider, coursesById)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    CourseOfferingProvider provider,
    Map<String, CourseModel> coursesById,
  ) {
    if (_selectedSemesterId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Text(
            AppStrings.selectSemesterFirst,
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (provider.isLoading && provider.offerings.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.offerings.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () =>
            provider.listenToSemesterOfferings(_selectedSemesterId!),
      );
    }

    if (provider.offerings.isEmpty) {
      return AppEmptyState(
        title: AppStrings.noOfferingsForSemester,
        description: AppStrings.noOfferingsForSemesterDesc,
        icon: Icons.event_repeat_rounded,
        actionLabel: AppStrings.addOfferingLabel,
        onAction: () => _openForm(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.huge,
      ),
      itemCount: provider.offerings.length,
      itemBuilder: (context, index) =>
          _buildOfferingCard(provider.offerings[index], coursesById),
    );
  }

  Widget _buildOfferingCard(
    CourseOfferingModel offering,
    Map<String, CourseModel> coursesById,
  ) {
    final course = coursesById[offering.courseId];
    final title = course?.title ?? AppStrings.unknownCourse;

    final (label: statusLabel, color: statusColor) = switch (offering.status) {
      CourseOfferingModel.statusActive => (
        label: AppStrings.activeStatus,
        color: AppColors.activeStatus,
      ),
      CourseOfferingModel.statusCancelled => (
        label: AppStrings.offeringStatusCancelled,
        color: AppColors.danger,
      ),
      _ => (label: AppStrings.archivedStatus, color: AppColors.textMuted),
    };

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: statusLabel,
                backgroundColor: statusColor.withValues(alpha: 0.08),
                foregroundColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (course != null)
                Text(
                  course.courseCode,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              AppStatusBadge(
                label: '${AppStrings.offeringSectionLabel} ${offering.section}',
                backgroundColor: AppColors.surfaceSecondary,
                foregroundColor: AppColors.textSecondary,
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
              Expanded(
                child: Text(
                  offering.instructorName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.divider),
          // Wrap لا Row: أربعة إجراءات لا تتسع في صف واحد على عرض 360،
          // فتلتف إلى سطر ثانٍ بدل أن يفيض الصف.
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.extraSmall,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.adminOfferingRoster,
                    arguments: OfferingRosterArgs(
                      offering: offering,
                      courseTitle: title,
                    ),
                  );
                },
                icon: const Icon(Icons.groups_rounded, size: 18),
                label: const Text(AppStrings.viewRosterAction),
              ),
              // الملفات تخص الطرح: يُمرَّر كاملًا فلا تسأل الشاشة التالية عن
              // المساق أو الفصل.
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.adminCourseFiles,
                    arguments: OfferingFilesArgs(
                      offering: offering,
                      courseTitle: title,
                    ),
                  );
                },
                icon: const Icon(Icons.folder_rounded, size: 18),
                label: const Text(AppStrings.offeringFilesAction),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                tooltip: AppStrings.editAction,
                onPressed: () => _openForm(offering: offering),
              ),
              IconButton(
                icon: Icon(
                  Icons.archive_rounded,
                  color: offering.isActive
                      ? AppColors.secondary
                      : AppColors.textDisabled,
                ),
                tooltip: AppStrings.archiveAction,
                onPressed: offering.isActive
                    ? () => _showArchiveDialog(offering, title)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
