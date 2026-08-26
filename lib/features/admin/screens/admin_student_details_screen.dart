import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../courses/models/student_course_view.dart';
import '../../enrollments/providers/admin_student_record_provider.dart';
import '../models/admin_student_model.dart';
import '../providers/admin_user_provider.dart';
import '../services/admin_user_service.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// تفاصيل طالب واحد للمشرف.
///
/// أُعيدت كتابتها بالكامل. المبدأ الذي تقوم عليه: الملف الشخصي يأتي من
/// وسيطة المسار مباشرةً، فيُرسم في أول إطار ولا يتوقف على أي مزوّد. حالات
/// السجل الأكاديمي — تحميل، فارغ، خطأ — تؤثر في منطقة السجل وحدها.
class AdminStudentDetailsScreen extends StatefulWidget {
  const AdminStudentDetailsScreen({super.key, required this.student});

  final AdminStudentModel student;

  @override
  State<AdminStudentDetailsScreen> createState() =>
      _AdminStudentDetailsScreenState();
}

class _AdminStudentDetailsScreenState extends State<AdminStudentDetailsScreen> {
  /*
   * الحالة المعروضة محليًا.
   *
   * الطالب يصل عبر وسيطة المسار وهو كائن غير قابل للتعديل، فبعد نجاح
   * الكتابة لا تتغيّر الوسيطة. نحتفظ بالحالة هنا ولا نحدّثها إلا بعد أن
   * تؤكد الخدمة نجاح الكتابة. قائمة الطلاب تحدّث نفسها من بثّ users.
   */
  late String _status = widget.student.status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminStudentRecordProvider>().loadForStudent(
        uid: widget.student.uid,
        majorId: widget.student.majorId,
      );
    });
  }

  bool get _isActive => _status == AdminUserService.statusActive;

  Future<void> _confirmAndApply() async {
    final disabling = _isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          disabling
              ? AppStrings.disableAccountConfirmTitle
              : AppStrings.activateAccountConfirmTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          disabling
              ? AppStrings.disableAccountConfirmBody
              : AppStrings.activateAccountConfirmBody,
          textAlign: TextAlign.right,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: disabling
                    ? AppColors.danger
                    : AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.confirmAction),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancelAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<AdminUserProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = disabling
        ? await provider.disableStudent(widget.student.uid)
        : await provider.activateStudent(widget.student.uid);

    if (!mounted) return;

    if (success) {
      // الحالة تتغيّر بعد تأكيد الكتابة لا قبله.
      setState(() {
        _status = disabling
            ? AdminUserService.statusDisabled
            : AdminUserService.statusActive;
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            disabling
                ? AppStrings.accountDisabledSuccess
                : AppStrings.accountActivatedSuccess,
          ),
        ),
      );
      return;
    }

    // فشل الكتابة يبقي الحالة السابقة كما هي.
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ?? AppStrings.accountStatusUpdateError,
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final record = context.watch<AdminStudentRecordProvider>();
    final userProvider = context.watch<AdminUserProvider>();

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(student.fullName),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.medium,
              AppSpacing.medium,
              AppSpacing.medium,
              AppSpacing.huge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileCard(student: student, status: _status),
                const SizedBox(height: AppSpacing.medium),
                _ProgramCard(student: student, majorName: record.majorName),
                const SizedBox(height: AppSpacing.medium),
                _AccountActionsCard(
                  isActive: _isActive,
                  isSaving: userProvider.isSaving,
                  onPressed: _confirmAndApply,
                ),
                const SizedBox(height: AppSpacing.medium),
                _AssignActionCard(student: student),
                const SizedBox(height: AppSpacing.medium),

                _SectionHeader(
                  title: AppStrings.currentEnrollmentsTitle,
                  count: record.hasLoaded
                      ? record.currentAttempts.length
                      : null,
                ),
                _RecordSection(
                  record: record,
                  views: record.currentAttempts,
                  emptyMessage: AppStrings.noCurrentEnrollmentsForStudent,
                  builder: (view) => _AttemptCard(view: view, isHistory: false),
                ),

                const SizedBox(height: AppSpacing.medium),
                _SectionHeader(
                  title: AppStrings.enrollmentHistoryTitle,
                  count: record.hasLoaded ? record.history.length : null,
                ),
                _RecordSection(
                  record: record,
                  views: record.history,
                  emptyMessage: AppStrings.noEnrollmentHistoryForStudent,
                  builder: (view) => _AttemptCard(view: view, isHistory: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ profile

/// معلومات الطالب. لا تقرأ أي مزوّد: مصدرها وسيطة المسار وحدها.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.student, required this.status});

  final AdminStudentModel student;

  /// الحالة المعروضة تأتي من الشاشة لا من الوسيطة: الوسيطة لا تتغيّر بعد
  /// تعطيل الحساب أو تفعيله.
  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == AdminUserService.statusActive;
    final statusColor = isActive ? AppColors.activeStatus : AppColors.danger;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    AppStatusBadge(
                      label: isActive
                          ? AppStrings.activeStatus
                          : AppStrings.disabledStatus,
                      backgroundColor: statusColor.withValues(alpha: 0.08),
                      foregroundColor: statusColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.divider),

          // الحقول الفارغة تُعرض بنص بديل بدل أن تختفي: اختفاء الصف يجعل
          // الشاشة تبدو فارغة بينما البيانات ببساطة غير مُدخَلة.
          _InfoRow(
            icon: Icons.badge_rounded,
            label: AppStrings.studentIdLabel,
            value: student.studentId,
          ),
          _InfoRow(
            icon: Icons.email_rounded,
            label: AppStrings.studentEmailLabel,
            value: student.email,
          ),
          _InfoRow(
            icon: Icons.school_outlined,
            label: AppStrings.academicLevelLabel,
            // يُخزَّن رقمًا ويُعرض نصًا عربيًا هنا فقط.
            value: student.academicLevel != null
                ? AppStrings.academicLevelDisplay(student.academicLevel!)
                : AppStrings.notProvidedValue,
          ),
          _InfoRow(
            icon: Icons.task_alt_rounded,
            label: AppStrings.onboardingCompletedLabel,
            value: student.onboardingCompleted
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
}

/// البرنامج الأكاديمي: الاسم الحقيقي من مستند التخصص، ثم النص الحر القديم
/// كبديل، ثم حالة "غير محدد" الصريحة.
class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.student, this.majorName});

  final AdminStudentModel student;
  final String? majorName;

  @override
  Widget build(BuildContext context) {
    final resolved = majorName != null && majorName!.trim().isNotEmpty;
    final legacy = student.major.trim();

    final String value;
    final bool isUnknown;
    if (resolved) {
      value = majorName!;
      isUnknown = false;
    } else if (legacy.isNotEmpty) {
      value = legacy;
      isUnknown = false;
    } else {
      value = AppStrings.majorNotAssigned;
      isUnknown = true;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.academicProgramTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
            textAlign: TextAlign.right,
          ),
          const Divider(color: AppColors.divider),
          _InfoRow(
            icon: Icons.school_rounded,
            label: AppStrings.majorLabel,
            value: value,
            valueColor: isUnknown ? AppColors.textMuted : null,
          ),
          // نوضّح أن الاسم المعروض نص قديم لا مرجع حقيقي، حتى لا يُظن
          // أن الطالب مرتبط ببرنامج أكاديمي فعلًا.
          if (!resolved && legacy.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                AppStrings.legacyMajorTextNote,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }
}

/// إجراءات الحساب: إجراء واحد ظاهر في كل حالة.
///
/// لا يُعرض الزران معًا: الحساب إمّا نشط فيُعطَّل، أو معطَّل فيُفعَّل.
class _AccountActionsCard extends StatelessWidget {
  const _AccountActionsCard({
    required this.isActive,
    required this.isSaving,
    required this.onPressed,
  });

  final bool isActive;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final actionColor = isActive ? AppColors.danger : AppColors.activeStatus;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.accountActionsTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            AppStrings.accountActionsDesc,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: AppSpacing.medium),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
            ),
            // التعطيل أثناء الحفظ يمنع ضغطة ثانية تُطلق كتابة موازية.
            onPressed: isSaving ? null : onPressed,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    isActive ? Icons.block_rounded : Icons.check_circle_outline,
                    size: 18,
                  ),
            label: Text(
              isActive
                  ? AppStrings.disableAccountAction
                  : AppStrings.activateAccountAction,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignActionCard extends StatelessWidget {
  const _AssignActionCard({required this.student});

  final AdminStudentModel student;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.assignedCoursesLabel,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            AppStrings.assignOfferingDesc,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: AppSpacing.medium),
          // زر بعرض البطاقة داخل عمود محدود العرض — لا Row ولا عرض لانهائي.
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.adminAssignCourses,
                arguments: student,
              );
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(AppStrings.assignCourseLabel),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- academic record

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.small,
        bottom: AppSpacing.small,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.small),
            AppStatusBadge(
              label: '$count',
              backgroundColor: AppColors.surfaceSecondary,
              foregroundColor: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

/// منطقة السجل: حالاتها الأربع محصورة هنا ولا تمس الملف الشخصي.
class _RecordSection extends StatelessWidget {
  const _RecordSection({
    required this.record,
    required this.views,
    required this.emptyMessage,
    required this.builder,
  });

  final AdminStudentRecordProvider record;
  final List<StudentCourseView> views;
  final String emptyMessage;
  final Widget Function(StudentCourseView view) builder;

  @override
  Widget build(BuildContext context) {
    if (record.isLoading && !record.hasLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.large),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (record.errorMessage != null && views.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            Text(
              record.errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.danger,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.small),
            TextButton(
              onPressed: () {
                final uid = record.studentUid;
                if (uid == null) return;
                record.loadForStudent(uid: uid);
              },
              child: const Text(AppStrings.retryLabel),
            ),
          ],
        ),
      );
    }

    if (views.isEmpty) {
      return AppCard(
        child: Text(
          emptyMessage,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // عمود لا ListView: الشاشة كلها داخل SingleChildScrollView واحد، وتداخل
    // قائمة قابلة للتمرير داخله هو مصدر أخطاء القياس المتكررة.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final view in views) builder(view)],
    );
  }
}

/// محاولة واحدة: تُحلّ عبر التسجيل ← الطرح ← المساق ← الفصل.
class _AttemptCard extends StatelessWidget {
  const _AttemptCard({required this.view, required this.isHistory});

  final StudentCourseView view;
  final bool isHistory;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  view.hasCourse ? view.title : AppStrings.unknownCourse,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              AppStatusBadge(
                label: '${AppStrings.attemptLabel} ${view.attemptNumber}',
                backgroundColor: view.isRetake
                    ? AppColors.warning.withValues(alpha: 0.12)
                    : AppColors.surfaceSecondary,
                foregroundColor: view.isRetake
                    ? AppColors.warningDark
                    : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (view.courseCode.isNotEmpty)
                Text(
                  view.courseCode,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              if (view.semesterName.isNotEmpty)
                AppStatusBadge(
                  label: view.semesterName,
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                  icon: Icons.event_note_rounded,
                ),
              if (view.section.isNotEmpty)
                AppStatusBadge(
                  label: '${AppStrings.sectionLabel} ${view.section}',
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                ),
              if (isHistory && view.completionStatus != null)
                AppStatusBadge(
                  label: AppStrings.completionStatusDisplay(
                    view.completionStatus,
                  ),
                  backgroundColor:
                      (view.enrollment.isPassed
                              ? AppColors.secondary
                              : AppColors.danger)
                          .withValues(alpha: 0.08),
                  foregroundColor: view.enrollment.isPassed
                      ? AppColors.secondary
                      : AppColors.danger,
                ),
              if (isHistory &&
                  view.grade != null &&
                  view.grade!.trim().isNotEmpty)
                AppStatusBadge(
                  label: '${AppStrings.gradeLabel}: ${view.grade}',
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                ),
            ],
          ),
          if (view.instructorName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    view.instructorName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// صف معلومة: عنصر مرن واحد فقط في الصف.
///
/// الشاشة القديمة كانت تضع Flexible و Expanded في الصف نفسه، وهو ما يجعل
/// القياس هشًّا عند تغيّر السياق.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? AppStrings.notProvidedValue : value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
