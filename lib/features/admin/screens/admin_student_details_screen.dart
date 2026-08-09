import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_destructive_button.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';
import '../../courses/models/course_model.dart';
import '../../courses/providers/course_provider.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../../enrollments/providers/enrollment_provider.dart';
import '../models/admin_student_model.dart';

class AdminStudentDetailsScreen extends StatefulWidget {
  const AdminStudentDetailsScreen({super.key, required this.student});

  final AdminStudentModel student;

  @override
  State<AdminStudentDetailsScreen> createState() =>
      _AdminStudentDetailsScreenState();
}

class _AdminStudentDetailsScreenState extends State<AdminStudentDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final enrollmentProvider = context.read<EnrollmentProvider>();
      enrollmentProvider.selectStudent(widget.student);
      context.read<CourseProvider>().listenToCourses();
    });
  }

  void _showRemoveDialog(
    BuildContext context,
    EnrollmentModel enrollment,
    String courseTitle,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            AppStrings.removeCourseTitle,
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          content: Text(
            '${AppStrings.removeCourseConfirm}\n($courseTitle)',
            textAlign: TextAlign.right,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppDestructiveButton(
                label: AppStrings.confirmAction,
                filled: true,
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  final provider = context.read<EnrollmentProvider>();
                  final success = await provider.removeEnrollment(
                    enrollment.offeringId,
                  );

                  if (!mounted) return;

                  if (success) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.courseRemovedSuccess),
                      ),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.errorMessage ?? AppStrings.courseSaveError,
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(AppStrings.cancelAction),
            ),
          ],
        );
      },
    );
  }

  void _showRestoreDialog(
    BuildContext context,
    EnrollmentModel enrollment,
    String courseTitle,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            AppStrings.restoreCourseTitle,
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          content: Text(
            '${AppStrings.restoreCourseConfirm}\n($courseTitle)',
            textAlign: TextAlign.right,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(AppStrings.cancelAction),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                final provider = context.read<EnrollmentProvider>();
                final success = await provider.restoreEnrollment(
                  enrollment.offeringId,
                );

                if (!mounted) return;

                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.courseRestoredSuccess),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? AppStrings.courseSaveError,
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text(AppStrings.confirmAction),
            ),
          ],
        );
      },
    );
  }

  void _showMarkCompletedDialog(
    BuildContext context,
    EnrollmentModel enrollment,
    String courseTitle,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            AppStrings.markCompletedTitle,
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          content: Text(
            '${AppStrings.markCompletedConfirm}\n($courseTitle)',
            textAlign: TextAlign.right,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  final provider = context.read<EnrollmentProvider>();
                  final success = await provider.markEnrollmentCompleted(
                    enrollment.offeringId,
                  );

                  if (!mounted) return;

                  if (success) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.enrollmentCompletedSuccess),
                      ),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.errorMessage ?? AppStrings.courseSaveError,
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: const Text(AppStrings.confirmAction),
              ),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.cancelAction),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountActionsCard(AdminStudentModel student) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.accountActionsTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          const Text(
            AppStrings.accountActionsDesc,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null, // Disabled UI-only
                  icon: const Icon(Icons.block_rounded),
                  label: const Text(AppStrings.disableAccountAction),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: null, // Disabled UI-only
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text(AppStrings.activateAccountAction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentProvider = context.watch<EnrollmentProvider>();
    final student = widget.student;
    final courseProvider = context.watch<CourseProvider>();
    final courses = courseProvider.courses;

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(student.fullName),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileCard(student),
              const SizedBox(height: AppSpacing.large),
              _buildAccountActionsCard(student),
              const SizedBox(height: AppSpacing.large),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.assignedCoursesLabel,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.adminAssignCourses,
                        arguments: student,
                      );
                    },
                    icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                    label: const Text(AppStrings.manageCoursesLabel),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              _buildEnrollmentsList(enrollmentProvider, courses, student.uid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AdminStudentModel student) {
    final statusColor = student.status == 'active'
        ? AppColors.activeStatus
        : AppColors.textMuted;
    final statusBackground = statusColor.withValues(alpha: 0.08);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  student.fullName,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                // حساب المستخدم يكون نشطًا أو معطّلًا، وليس "مؤرشفًا".
                label: student.isActive
                    ? AppStrings.activeStatus
                    : AppStrings.filterDisabled,
                backgroundColor: statusBackground,
                foregroundColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _buildInfoRow(
            Icons.badge_rounded,
            AppStrings.studentIdLabel,
            student.studentId,
          ),
          _buildInfoRow(
            Icons.email_rounded,
            AppStrings.studentEmailLabel,
            student.email,
          ),
          if (student.major.isNotEmpty)
            _buildInfoRow(
              Icons.school_rounded,
              AppStrings.majorLabel,
              student.major,
            ),
          if (student.academicLevel != null)
            _buildInfoRow(
              Icons.school_outlined,
              AppStrings.academicLevelLabel,
              AppStrings.academicLevelDisplay(student.academicLevel!),
            ),
          _buildInfoRow(
            Icons.task_alt_rounded,
            AppStrings.onboardingCompletedLabel,
            student.onboardingCompleted
                ? AppStrings.completedOnboarding
                : AppStrings.pendingOnboarding,
            valueColor: student.onboardingCompleted
                ? AppColors.activeStatus
                : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label: ',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsList(
    EnrollmentProvider provider,
    List<CourseModel> courses,
    String studentUid,
  ) {
    if (provider.isLoadingEnrollments) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                provider.loadStudentEnrollments(studentUid);
              },
              child: const Text(AppStrings.retryLabel),
            ),
          ],
        ),
      );
    }

    if (provider.selectedStudentEnrollments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Center(
          child: Text(
            AppStrings.noCoursesEnrolledForStudent,
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final coursesById = <String, CourseModel>{};
    for (final course in courses) {
      coursesById[course.id] = course;
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.selectedStudentEnrollments.length,
      itemBuilder: (context, index) {
        final enrollment = provider.selectedStudentEnrollments[index];
        final course = coursesById[enrollment.courseId];
        final courseTitle = course?.title ?? AppStrings.unknownCourse;
        final courseCode = course?.courseCode ?? '';

        final String statusLabel;
        final Color statusColor;
        if (enrollment.isActive) {
          statusLabel = AppStrings.activeEnrollmentStatus;
          statusColor = AppColors.activeStatus;
        } else if (enrollment.isCompleted) {
          statusLabel = AppStrings.completedEnrollmentStatus;
          statusColor = AppColors.secondary;
        } else {
          statusLabel = AppStrings.removedEnrollmentStatus;
          statusColor = AppColors.danger;
        }
        final statusBackground = statusColor.withValues(alpha: 0.08);

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
                      courseTitle,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppStatusBadge(
                    label: statusLabel,
                    backgroundColor: statusBackground,
                    foregroundColor: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              if (courseCode.isNotEmpty)
                _buildInfoRow(
                  Icons.code_rounded,
                  AppStrings.courseCodeLabel,
                  courseCode,
                ),
              /*
               * اسم المدرّس صار من بيانات الطرح لا المساق، ولا تُحمَّل
               * الطروحات في هذه الشاشة. نعرض بدلًا منه رقم المحاولة، وهو ما
               * يميّز إعادة دراسة المساق عن دراسته أول مرة.
               */
              if (enrollment.isRetake)
                _buildInfoRow(
                  Icons.repeat_rounded,
                  AppStrings.attemptLabel,
                  '${enrollment.attemptNumber}',
                ),
              if (!enrollment.hasOffering)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.small),
                  child: Text(
                    AppStrings.legacyEnrollmentNote,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warningDark,
                    ),
                  ),
                ),
              const Divider(height: 20, color: AppColors.divider),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  if (enrollment.isActive)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                      ),
                      onPressed: () {
                        _showMarkCompletedDialog(
                          context,
                          enrollment,
                          courseTitle,
                        );
                      },
                      icon: const Icon(Icons.task_alt_rounded, size: 18),
                      label: const Text(AppStrings.markCompletedAction),
                    ),
                  if (enrollment.isActive)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      onPressed: () {
                        _showRemoveDialog(context, enrollment, courseTitle);
                      },
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 18,
                      ),
                      label: const Text(AppStrings.cancelEnrollmentAction),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _showRestoreDialog(context, enrollment, courseTitle);
                      },
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text(AppStrings.restoreEnrollmentAction),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
