import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_destructive_button.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../assignments/models/course_assignment_model.dart';
import '../../assignments/providers/course_assignment_provider.dart';
import '../../assignments/widgets/assignment_status_chips.dart';
import '../../courses/providers/course_provider.dart';
import '../providers/admin_teacher_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';
import 'admin_assignment_list_screen.dart';

/// تفاصيل واجب من منظور المشرف: قراءة فقط، مع أرشفة إشرافية.
///
/// لا تعديل للعنوان ولا للتعليمات ولا للموعد ولا للأولوية. المشرف يشرف على
/// المحتوى الأكاديمي ولا يؤلّفه؛ القواعد تحصر تعديله في status و updatedAt
/// وتشترط أن تصبح الحالة 'archived'، وهذه الشاشة لا تعرض أكثر مما تسمح به.
class AdminAssignmentDetailsScreen extends StatelessWidget {
  const AdminAssignmentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final assignment = arguments is AdminAssignmentDetailsArgs
        ? arguments.assignment
        : null;

    if (assignment == null) {
      return const AdminAccessGuard(
        child: Scaffold(
          body: Center(child: Text(AppStrings.assignmentNotFound)),
        ),
      );
    }

    final provider = context.watch<CourseAssignmentProvider>();

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.assignmentDetailsScreenTitle),
          leading: const AdminBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(context, assignment),
              const SizedBox(height: AppSpacing.large),
              _buildInstructionsCard(assignment),
              const SizedBox(height: AppSpacing.extraLarge),
              _buildModerationSection(context, assignment, provider),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    CourseAssignmentModel assignment,
  ) {
    final courses = context.watch<CourseProvider>().courses;
    String? courseTitle;
    for (final course in courses) {
      if (course.id == assignment.courseId) {
        courseTitle = '${course.courseCode} — ${course.title}';
        break;
      }
    }

    /*
     * اسم المعلّم يُحلّ من قائمة المعلّمين إن كانت محمَّلة، ولا يُقرأ من
     * الواجب: الواجب يحمل createdBy معرّفًا لا اسمًا. تعذّر الحلّ يعني عدم
     * عرض السطر أصلًا بدل عرض معرّف خام.
     */
    final teacherName = context.watch<AdminTeacherProvider>().teachers
        .where((teacher) => teacher.uid == assignment.createdBy)
        .map((teacher) => teacher.displayName)
        .firstOrNull;

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
          if (courseTitle != null) ...[
            const SizedBox(height: 4),
            Text(
              courseTitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ],
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
              AppStatusBadge(
                label: assignment.isActive
                    ? AppStrings.activeStatus
                    : AppStrings.archivedStatus,
                backgroundColor:
                    (assignment.isActive
                            ? AppColors.secondary
                            : AppColors.textMuted)
                        .withValues(alpha: 0.08),
                foregroundColor: assignment.isActive
                    ? AppColors.secondary
                    : AppColors.textMuted,
              ),
            ],
          ),
          if (teacherName != null) ...[
            const SizedBox(height: AppSpacing.small),
            _infoLine(
              Icons.co_present_rounded,
              AppStrings.assignmentTeacherLabel,
              teacherName,
            ),
          ],
          if (assignment.createdAt != null)
            _infoLine(
              Icons.schedule_rounded,
              AppStrings.assignmentCreatedAtLabel,
              DateFormat('yyyy/MM/dd', 'ar').format(assignment.createdAt!),
            ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
          // نص للعرض لا حقل إدخال: لا يملك المشرف تعديله.
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

  Widget _buildModerationSection(
    BuildContext context,
    CourseAssignmentModel assignment,
    CourseAssignmentProvider provider,
  ) {
    // الواجب المؤرشف لا يُؤرشف مرتين، ولا يملك المشرف إعادته.
    if (assignment.isArchived) return const SizedBox.shrink();

    return AppDestructiveButton(
      label: AppStrings.adminModerateArchiveAction,
      icon: Icons.archive_outlined,
      isLoading: provider.isSaving,
      onPressed: provider.isSaving
          ? null
          : () => _confirmModerate(context, assignment, provider),
    );
  }

  Future<void> _confirmModerate(
    BuildContext context,
    CourseAssignmentModel assignment,
    CourseAssignmentProvider provider,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.adminModerateArchiveConfirmTitle),
        content: const Text(AppStrings.adminModerateArchiveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              AppStrings.adminModerateArchiveAction,
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // مسار إشرافي منفصل عن أرشفة المعلّم: يكتب status و updatedAt فقط.
    final success = await provider.moderateArchiveAssignment(assignment.id);

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

    if (success) navigator.pop();
  }
}
