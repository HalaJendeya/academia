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
import '../../../core/widgets/error_state.dart';
import '../../academics/models/major_model.dart';
import '../../academics/providers/academic_structure_provider.dart';
import '../../courses/models/course_model.dart';
import '../../courses/providers/course_provider.dart';
import '../../curriculum/models/curriculum_course_model.dart';
import '../../curriculum/providers/curriculum_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';
import 'admin_curriculum_entry_form_screen.dart';

/// الخطة الدراسية لتخصص واحد، مجمّعة بالمستويات 1..8.
///
/// الخطة تخلط نوعين من الصفوف: مساقات محددة، وخانات متطلبات لم يُختَر لها
/// مساق بعد. الخانات ليست مساقات ولا تفتح تفاصيل مساق.
class AdminCurriculumScreen extends StatefulWidget {
  const AdminCurriculumScreen({super.key});

  @override
  State<AdminCurriculumScreen> createState() => _AdminCurriculumScreenState();
}

class _AdminCurriculumScreenState extends State<AdminCurriculumScreen> {
  String? _selectedMajorId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is MajorModel) _selectedMajorId = arguments.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicStructureProvider>().listenToStructure();
      context.read<CourseProvider>().listenToCourses();
      if (_selectedMajorId != null) {
        context.read<CurriculumProvider>().listenToCurriculum(_selectedMajorId!);
      }
    });

    _initialized = true;
  }

  void _selectMajor(String? majorId) {
    if (majorId == null || majorId == _selectedMajorId) return;
    setState(() => _selectedMajorId = majorId);
    context.read<CurriculumProvider>().listenToCurriculum(majorId);
  }

  void _openEntryForm({CurriculumCourseModel? entry}) {
    final majorId = _selectedMajorId;
    if (majorId == null) return;

    Navigator.of(context).pushNamed(
      AppRoutes.adminCurriculumEntry,
      arguments: CurriculumEntryFormArgs(majorId: majorId, entry: entry),
    );
  }

  void _showRemoveDialog(CurriculumCourseModel entry, String rowTitle) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          AppStrings.removeCurriculumEntryTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          '${AppStrings.removeCurriculumEntryConfirm}\n($rowTitle)',
          textAlign: TextAlign.right,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                final provider = context.read<CurriculumProvider>();
                final success = await provider.removeEntry(entry.id);

                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  success
                      ? const SnackBar(
                          content: Text(
                            AppStrings.curriculumEntryRemovedSuccess,
                          ),
                        )
                      : SnackBar(
                          content: Text(
                            provider.errorMessage ??
                                AppStrings.curriculumSaveError,
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

  @override
  Widget build(BuildContext context) {
    final structure = context.watch<AcademicStructureProvider>();
    final curriculum = context.watch<CurriculumProvider>();
    final courses = context.watch<CourseProvider>().courses;
    final coursesById = {for (final course in courses) course.id: course};

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.curriculumManagementTitle),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        floatingActionButton: _selectedMajorId == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _openEntryForm(),
                label: const Text(AppStrings.addCurriculumEntryLabel),
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
                    (_selectedMajorId != null &&
                        structure.majorsById.containsKey(_selectedMajorId))
                    ? _selectedMajorId
                    : null,
                // أسماء التخصصات العربية طويلة: بدون isExpanded يحاول العنصر
                // أخذ عرضه الطبيعي فيفيض الصف على الشاشات الضيقة.
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_rounded),
                  hintText: AppStrings.selectMajorHint,
                ),
                items: structure.majors
                    .map(
                      (major) => DropdownMenuItem<String>(
                        value: major.id,
                        child: Text(
                          '${major.name} (${major.code})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _selectMajor,
              ),
            ),
            Expanded(child: _buildBody(curriculum, coursesById)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    CurriculumProvider provider,
    Map<String, CourseModel> coursesById,
  ) {
    if (_selectedMajorId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Text(
            AppStrings.selectMajorPrompt,
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (provider.isLoading && provider.entries.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.entries.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () => provider.listenToCurriculum(_selectedMajorId!),
      );
    }

    if (provider.entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Text(
            AppStrings.curriculumEmptyForMajor,
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // ساعات صف المساق تأتي من مستند المساق نفسه؛ الخانات وحدها تخزّن ساعاتها.
    int hoursOf(CurriculumCourseModel entry) => entry.isSlotEntry
        ? (entry.creditHours ?? 0)
        : (coursesById[entry.courseId]?.creditHours ?? 0);

    final levels = provider.levels;
    final totalHours = provider.entries.fold<int>(
      0,
      (sum, entry) => sum + hoursOf(entry),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.huge,
      ),
      children: [
        _buildSummaryCard(provider.entries.length, totalHours),
        for (final level in levels) ...[
          _buildLevelHeader(
            level,
            provider
                .entriesForLevel(level)
                .fold<int>(0, (sum, entry) => sum + hoursOf(entry)),
          ),
          ...provider
              .entriesForLevel(level)
              .map((entry) => _buildEntryCard(entry, coursesById, hoursOf)),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(int rowCount, int totalHours) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              Icons.list_alt_rounded,
              AppStrings.curriculumRowsLabel,
              '$rowCount',
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.divider),
          Expanded(
            child: _buildSummaryItem(
              Icons.hourglass_bottom_rounded,
              AppStrings.curriculumTotalHoursLabel,
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
        ),
      ],
    );
  }

  Widget _buildLevelHeader(int level, int levelHours) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.medium,
        bottom: AppSpacing.small,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppStrings.academicLevelDisplay(level),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const Spacer(),
          Text(
            '$levelHours ${AppStrings.creditHoursShort}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(
    CurriculumCourseModel entry,
    Map<String, CourseModel> coursesById,
    int Function(CurriculumCourseModel) hoursOf,
  ) {
    final course = entry.isCourseEntry ? coursesById[entry.courseId] : null;
    final isSlot = entry.isSlotEntry;
    final title = isSlot
        ? (entry.slotLabel ?? '')
        : (course?.title ?? AppStrings.unknownCourse);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSlot
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${hoursOf(entry)} ${AppStrings.creditHoursShort}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!isSlot && course != null)
                Text(
                  course.courseCode,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              AppStatusBadge(
                label: AppStrings.requirementTypeDisplay(entry.requirementType),
                backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
                foregroundColor: AppColors.secondary,
              ),
              if (isSlot)
                AppStatusBadge(
                  label: AppStrings.slotEntryBadge,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                  foregroundColor: AppColors.warningDark,
                ),
            ],
          ),
          if (isSlot) ...[
            const SizedBox(height: 6),
            Text(
              AppStrings.slotNotSelectableNote,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          if (entry.prerequisiteText != null &&
              entry.prerequisiteText!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.link_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${AppStrings.prerequisiteLabel}: ${entry.prerequisiteText}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 18, color: AppColors.divider),
          Row(
            children: [
              // الخانات ليست مساقات: لا تفتح شاشة تفاصيل مساق.
              if (!isSlot && course != null)
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.adminCourseDetails,
                      arguments: course,
                    );
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text(AppStrings.viewAction),
                ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                tooltip: AppStrings.editAction,
                onPressed: () => _openEntryForm(entry: entry),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.danger,
                ),
                tooltip: AppStrings.deleteAction,
                onPressed: () => _showRemoveDialog(entry, title),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
