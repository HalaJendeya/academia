import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../courses/models/course_offering_model.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../../enrollments/providers/enrollment_provider.dart';
import '../models/admin_student_model.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';
import '../widgets/record_result_dialog.dart';

class OfferingRosterArgs {
  const OfferingRosterArgs({required this.offering, required this.courseTitle});

  final CourseOfferingModel offering;
  final String courseTitle;
}

/// الطلاب المسجَّلون في طرح واحد.
///
/// هذه الشاشة تُغلق الدورة: الطرح يُنشأ، الطالب يُسجَّل فيه، ثم تُسجَّل
/// نتيجته هنا. تسجيل النتيجة يُنهي المحاولة، وإعادة الدراسة تصبح محاولة
/// جديدة في طرح فصل لاحق.
class AdminOfferingRosterScreen extends StatefulWidget {
  const AdminOfferingRosterScreen({super.key});

  @override
  State<AdminOfferingRosterScreen> createState() =>
      _AdminOfferingRosterScreenState();
}

class _AdminOfferingRosterScreenState extends State<AdminOfferingRosterScreen> {
  OfferingRosterArgs? _args;
  bool _initialized = false;

  /// مرجع محفوظ للمزوّد.
  ///
  /// لا يمكن قراءة المزوّد من context داخل dispose لأن العنصر يكون قد خرج
  /// من الشجرة، لذلك نلتقطه أثناء ربط التبعيات ونستعمله عند التنظيف.
  EnrollmentProvider? _enrollmentProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enrollmentProvider = context.read<EnrollmentProvider>();

    if (_initialized) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is OfferingRosterArgs) _args = arguments;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<EnrollmentProvider>();
      // أسماء الطلاب تأتي من قائمة الطلاب نفسها؛ التسجيل يحمل المعرّف فقط.
      provider.listenToStudents();
      final offeringId = _args?.offering.id;
      if (offeringId != null) provider.listenToOfferingRoster(offeringId);
    });

    _initialized = true;
  }

  @override
  void dispose() {
    // القائمة خاصة بهذه الشاشة: نوقف بثّها عند مغادرتها. الدالة لا تُشعر
    // المستمعين، فاستدعاؤها أثناء التفكيك آمن.
    _enrollmentProvider?.stopListeningToRoster();
    super.dispose();
  }

  Future<void> _recordResult(
    EnrollmentModel enrollment,
    String studentName,
  ) async {
    final provider = context.read<EnrollmentProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final outcome = await showRecordResultDialog(
      context: context,
      courseTitle: '${_args?.courseTitle ?? ''}\n$studentName',
      initialCompletionStatus: enrollment.completionStatus,
      initialGrade: enrollment.grade,
    );

    if (outcome == null || !mounted) return;

    final success = await provider.setCompletionStatusFor(
      userId: enrollment.userId,
      offeringId: enrollment.offeringId,
      completionStatus: outcome.completionStatus,
      grade: outcome.grade,
    );

    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      success
          ? const SnackBar(content: Text(AppStrings.resultRecordedSuccess))
          : SnackBar(
              content: Text(
                provider.errorMessage ?? AppStrings.courseSaveError,
              ),
              backgroundColor: AppColors.error,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnrollmentProvider>();
    final args = _args;

    if (args == null) {
      return const AdminAccessGuard(
        child: Scaffold(
          body: Center(child: Text(AppStrings.offeringNotFound)),
        ),
      );
    }

    final studentsById = {
      for (final student in provider.students) student.uid: student,
    };

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.offeringRosterTitle),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        body: Column(
          children: [
            _buildOfferingHeader(args, provider.roster.length),
            Expanded(child: _buildBody(provider, studentsById)),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferingHeader(OfferingRosterArgs args, int count) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              args.courseTitle,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppStatusBadge(
                  label:
                      '${AppStrings.offeringSectionLabel} '
                      '${args.offering.section}',
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                ),
                AppStatusBadge(
                  label: args.offering.instructorName,
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                  icon: Icons.person_rounded,
                ),
                AppStatusBadge(
                  label: '${AppStrings.offeringRosterCountLabel}: $count',
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  foregroundColor: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    EnrollmentProvider provider,
    Map<String, AdminStudentModel> studentsById,
  ) {
    if (provider.isLoadingRoster && provider.roster.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.roster.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.offeringRosterEmpty,
        description: AppStrings.offeringRosterEmptyDesc,
        icon: Icons.groups_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.huge,
      ),
      itemCount: provider.roster.length,
      itemBuilder: (context, index) {
        final enrollment = provider.roster[index];
        final student = studentsById[enrollment.userId];
        return _buildRosterCard(enrollment, student, provider);
      },
    );
  }

  Widget _buildRosterCard(
    EnrollmentModel enrollment,
    AdminStudentModel? student,
    EnrollmentProvider provider,
  ) {
    final name = student?.fullName ?? enrollment.userId;

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
                  name,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // رقم المحاولة معلومة أكاديمية: الثالثة تختلف عن الأولى.
              AppStatusBadge(
                label:
                    '${AppStrings.attemptLabel} ${enrollment.attemptNumber}',
                backgroundColor: enrollment.isRetake
                    ? AppColors.warning.withValues(alpha: 0.12)
                    : AppColors.surfaceSecondary,
                foregroundColor: enrollment.isRetake
                    ? AppColors.warningDark
                    : AppColors.textSecondary,
              ),
            ],
          ),
          if (student != null && student.studentId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              student.studentId,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
          ],
          if (enrollment.completionStatus != null) ...[
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: 6,
              children: [
                AppStatusBadge(
                  label: AppStrings.completionStatusDisplay(
                    enrollment.completionStatus,
                  ),
                  backgroundColor:
                      (enrollment.isPassed
                              ? AppColors.secondary
                              : AppColors.danger)
                          .withValues(alpha: 0.08),
                  foregroundColor: enrollment.isPassed
                      ? AppColors.secondary
                      : AppColors.danger,
                ),
                if (enrollment.grade != null &&
                    enrollment.grade!.trim().isNotEmpty)
                  AppStatusBadge(
                    label: '${AppStrings.gradeLabel}: ${enrollment.grade}',
                    backgroundColor: AppColors.surfaceSecondary,
                    foregroundColor: AppColors.textSecondary,
                  ),
              ],
            ),
          ],
          const Divider(height: 24, color: AppColors.divider),
          Row(
            children: [
              TextButton.icon(
                onPressed: provider.isSaving
                    ? null
                    : () => _recordResult(enrollment, name),
                icon: const Icon(Icons.task_alt_rounded, size: 18),
                label: const Text(AppStrings.recordResultAction),
              ),
              const Spacer(),
              IconButton(
                tooltip: AppStrings.cancelEnrollmentAction,
                icon: const Icon(
                  Icons.remove_circle_outline_rounded,
                  color: AppColors.danger,
                ),
                onPressed: provider.isSaving
                    ? null
                    : () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final success = await provider.removeEnrollmentFor(
                          userId: enrollment.userId,
                          offeringId: enrollment.offeringId,
                        );
                        if (!mounted) return;
                        scaffoldMessenger.showSnackBar(
                          success
                              ? const SnackBar(
                                  content: Text(
                                    AppStrings.courseRemovedSuccess,
                                  ),
                                )
                              : SnackBar(
                                  content: Text(
                                    provider.errorMessage ??
                                        AppStrings.courseSaveError,
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                        );
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
