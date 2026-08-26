import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_destructive_button.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../assignments/models/course_assignment_model.dart';
import '../../assignments/providers/course_assignment_provider.dart';
import '../../assignments/widgets/assignment_status_chips.dart';
import '../models/teacher_offering_view.dart';
import '../providers/teacher_offerings_provider.dart';
import '../widgets/teacher_access_guard.dart';
import 'teacher_assignments_screen.dart';

/// تفاصيل واجب واحد يملكه المعلّم، ومنها التعديل والأرشفة.
///
/// الواجب يُقرأ من القائمة الحيّة بمعرّفه لا من نسخة مُمرَّرة: أرشفته أو
/// سحب إسناد طرحه بينما الشاشة مفتوحة يجب أن يُفرغها، لا أن تبقى تعرض
/// محتوى لم يعد للمعلّم.
class TeacherAssignmentDetailsScreen extends StatelessWidget {
  const TeacherAssignmentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final assignmentId = arguments is TeacherAssignmentDetailsArgs
        ? arguments.assignmentId
        : null;

    final provider = context.watch<CourseAssignmentProvider>();
    final offeringsProvider = context.watch<TeacherOfferingsProvider>();

    final assignment = _findAssignment(provider, assignmentId);

    /*
     * الملكية تُتحقَّق هنا للعرض فقط. الخدمة تعيد قراءة الطرح، والقواعد
     * تفرض الشرط نفسه على الخادم؛ هذه الشاشة لا تمنح صلاحية ولا تحجبها.
     */
    final offering = assignment == null
        ? null
        : _findOffering(offeringsProvider, assignment.offeringId);

    return TeacherAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.assignmentDetailsScreenTitle),
          centerTitle: true,
        ),
        body: assignment == null || offering == null
            ? const AppEmptyState(
                title: AppStrings.assignmentNotOwnedTitle,
                description: AppStrings.assignmentNotOwnedDesc,
                icon: Icons.assignment_late_outlined,
              )
            : _buildBody(context, assignment, offering, provider),
      ),
    );
  }

  static CourseAssignmentModel? _findAssignment(
    CourseAssignmentProvider provider,
    String? assignmentId,
  ) {
    if (assignmentId == null || assignmentId.trim().isEmpty) return null;
    for (final assignment in provider.assignments) {
      if (assignment.id == assignmentId) return assignment;
    }
    return null;
  }

  static TeacherOfferingView? _findOffering(
    TeacherOfferingsProvider provider,
    String offeringId,
  ) {
    for (final view in provider.offerings) {
      if (view.offeringId == offeringId) return view;
    }
    return null;
  }

  Widget _buildBody(
    BuildContext context,
    CourseAssignmentModel assignment,
    TeacherOfferingView offering,
    CourseAssignmentProvider provider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(assignment, offering),
          const SizedBox(height: AppSpacing.large),
          _buildInstructionsCard(assignment),
          const SizedBox(height: AppSpacing.extraLarge),
          _buildActions(context, assignment, provider),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    CourseAssignmentModel assignment,
    TeacherOfferingView offering,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assignment.title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 4),
          Text(
            '${offering.displayTitle} · '
            '${AppStrings.offeringSectionLabel} ${offering.section}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.right,
          ),
          const Divider(height: 24, color: AppColors.divider),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusBadge(
                label:
                    '${AppStrings.assignmentDueAtLabel}: '
                    '${assignment.dueDateLabel}',
                backgroundColor: AppColors.surfaceSecondary,
                foregroundColor: AppColors.textSecondary,
                icon: Icons.event_rounded,
              ),
              AssignmentPriorityBadge(priority: assignment.priority),
              AssignmentDueStateBadge(assignment: assignment),
              if (assignment.isArchived)
                const AppStatusBadge(
                  label: AppStrings.archivedStatus,
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textMuted,
                ),
            ],
          ),
          if (assignment.createdAt != null) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              '${AppStrings.assignmentCreatedAtLabel}: '
              '${DateFormat('yyyy/MM/dd', 'ar').format(assignment.createdAt!)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(CourseAssignmentModel assignment) {
    final hasInstructions = assignment.description.trim().isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.assignmentInstructionsSectionTitle,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const Divider(color: AppColors.divider),
          Text(
            hasInstructions
                ? assignment.description
                : AppStrings.assignmentNoInstructions,
            style: AppTextStyles.bodyMedium.copyWith(
              color: hasInstructions
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    CourseAssignmentModel assignment,
    CourseAssignmentProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: provider.isSaving
              ? null
              : () => Navigator.of(context).pushNamed(
                  AppRoutes.teacherAddAssignment,
                  arguments: TeacherAssignmentFormArgs(assignment: assignment),
                ),
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text(AppStrings.editAssignmentTitle),
        ),
        const SizedBox(height: AppSpacing.medium),
        // أرشفة لا حذف: الحذف النهائي مرفوض للجميع في القواعد.
        AppDestructiveButton(
          label: AppStrings.archiveAssignmentAction,
          icon: Icons.archive_outlined,
          isLoading: provider.isSaving,
          onPressed: provider.isSaving
              ? null
              : () => _confirmArchive(context, assignment, provider),
        ),
      ],
    );
  }

  Future<void> _confirmArchive(
    BuildContext context,
    CourseAssignmentModel assignment,
    CourseAssignmentProvider provider,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.archiveAssignmentConfirmTitle),
        content: const Text(AppStrings.archiveAssignmentConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              AppStrings.archiveAssignmentAction,
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await provider.archiveAssignment(assignment.id);

    scaffoldMessenger.showSnackBar(
      success
          ? const SnackBar(content: Text(AppStrings.assignmentArchivedSuccess))
          : SnackBar(
              content: Text(
                provider.errorMessage ?? AppStrings.assignmentUpdateError,
              ),
              backgroundColor: AppColors.error,
            ),
    );

    // الواجب المؤرشف يغادر البثّ النشط، فالشاشة تفقد مصدرها.
    if (success) navigator.pop();
  }
}
