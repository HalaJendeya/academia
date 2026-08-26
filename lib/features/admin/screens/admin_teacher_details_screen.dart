import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_destructive_button.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/primary_button.dart';
import '../../courses/models/course_offering_model.dart';
import '../../courses/providers/course_provider.dart';
import '../../semesters/providers/semester_provider.dart';
import '../models/admin_teacher_model.dart';
import '../providers/admin_teacher_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// بيانات معلّم واحد: هويته، حالة حسابه، والطروحات المسندة إليه فعلًا.
///
/// عدد الطروحات مقروء من courseOfferings حيث teacherId يساوي معرّفه، لا
/// محسوب من اسم المدرّس النصي: الاسم نص حر لا يُطابق حسابًا.
class AdminTeacherDetailsScreen extends StatefulWidget {
  const AdminTeacherDetailsScreen({super.key});

  @override
  State<AdminTeacherDetailsScreen> createState() =>
      _AdminTeacherDetailsScreenState();
}

class _AdminTeacherDetailsScreenState extends State<AdminTeacherDetailsScreen> {
  /// مرجع محفوظ: لا يمكن قراءة المزوّد من context أثناء التفكيك.
  AdminTeacherProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<AdminTeacherProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // أسماء المساقات والفصول تأتي من مزوّديها؛ الطرح يحمل المعرّفات فقط.
      context.read<CourseProvider>().listenToCourses();
      context.read<SemesterProvider>().listenToSemesters();
    });
  }

  @override
  void dispose() {
    // بثّ الطروحات خاص بهذه الشاشة.
    _provider?.stopListeningToOfferings();
    super.dispose();
  }

  Future<void> _toggleStatus(AdminTeacherModel teacher) async {
    final provider = context.read<AdminTeacherProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (teacher.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(AppStrings.disableTeacherConfirmTitle),
          content: const Text(AppStrings.disableTeacherConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.cancelAction),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                AppStrings.disableTeacherAction,
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final nextStatus = teacher.isActive
        ? AdminTeacherModel.statusDisabled
        : AdminTeacherModel.statusActive;

    final success = await provider.setTeacherStatus(
      uid: teacher.uid,
      status: nextStatus,
    );

    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      success
          ? SnackBar(
              content: Text(
                nextStatus == AdminTeacherModel.statusActive
                    ? AppStrings.teacherEnabledSuccess
                    : AppStrings.teacherDisabledSuccess,
              ),
            )
          : SnackBar(
              content: Text(
                provider.errorMessage ?? AppStrings.teacherSaveError,
              ),
              backgroundColor: AppColors.error,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminTeacherProvider>();
    final teacher = provider.selectedTeacher;

    if (teacher == null) {
      return const AdminAccessGuard(
        child: Scaffold(body: Center(child: Text(AppStrings.teacherNotFound))),
      );
    }

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.teacherDetailsTitle),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIdentityCard(teacher),
              const SizedBox(height: AppSpacing.large),
              _buildOfferingsCard(provider),
              const SizedBox(height: AppSpacing.extraLarge),
              _buildStatusAction(teacher, provider),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityCard(AdminTeacherModel teacher) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.co_present_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.displayName,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const AppStatusBadge(
                      label: AppStrings.teacherRoleLabel,
                      backgroundColor: AppColors.surfaceSecondary,
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.divider),
          _buildInfoRow(
            Icons.email_outlined,
            AppStrings.studentEmailLabel,
            teacher.email,
            isLtr: true,
          ),
          _buildInfoRow(
            Icons.security_rounded,
            AppStrings.accountStatusLabel,
            teacher.isActive
                ? AppStrings.teacherAccountActiveLabel
                : AppStrings.teacherAccountDisabledLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLtr = false,
  }) {
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
              value.isEmpty ? '—' : value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textDirection: isLtr ? TextDirection.ltr : null,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferingsCard(AdminTeacherProvider provider) {
    final offerings = provider.selectedTeacherOfferings;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.teacherAssignedOfferingsTitle,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              /*
               * العدد يُعرض فقط بعد اكتمال التحميل: صفر أثناء التحميل ادّعاء
               * بأن المعلّم بلا طروحات، وهو ما لا نعرفه بعد.
               */
              if (!provider.isLoadingOfferings)
                AppStatusBadge(
                  label: '${offerings.length}',
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  foregroundColor: AppColors.primary,
                ),
            ],
          ),
          const Divider(color: AppColors.divider),
          if (provider.isLoadingOfferings)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else if (offerings.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Text(
                AppStrings.teacherNoAssignedOfferings,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...offerings.map(_buildOfferingRow),
        ],
      ),
    );
  }

  Widget _buildOfferingRow(CourseOfferingModel offering) {
    final course = context.watch<CourseProvider>().courses.where(
      (c) => c.id == offering.courseId,
    );
    final title = course.isEmpty
        ? offering.courseId
        : '${course.first.courseCode} — ${course.first.title}';
    final semesterName = context.watch<SemesterProvider>().semesterNameFor(
      offering.semesterId,
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: 4,
            children: [
              AppStatusBadge(
                label: semesterName,
                backgroundColor: AppColors.surfaceSecondary,
                foregroundColor: AppColors.textSecondary,
                icon: Icons.event_note_rounded,
              ),
              AppStatusBadge(
                label:
                    '${AppStrings.offeringSectionLabel} ${offering.section}',
                backgroundColor: AppColors.surfaceSecondary,
                foregroundColor: AppColors.textSecondary,
              ),
              AppStatusBadge(
                label: offering.isActive
                    ? AppStrings.activeStatus
                    : AppStrings.archivedStatus,
                backgroundColor:
                    (offering.isActive
                            ? AppColors.secondary
                            : AppColors.textMuted)
                        .withValues(alpha: 0.08),
                foregroundColor: offering.isActive
                    ? AppColors.secondary
                    : AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAction(
    AdminTeacherModel teacher,
    AdminTeacherProvider provider,
  ) {
    if (teacher.isActive) {
      return AppDestructiveButton(
        label: AppStrings.disableTeacherAction,
        icon: Icons.block_rounded,
        onPressed: provider.isSaving ? null : () => _toggleStatus(teacher),
      );
    }

    return AppPrimaryButton(
      label: AppStrings.enableTeacherAction,
      isLoading: provider.isSaving,
      isEnabled: !provider.isSaving,
      onPressed: () => _toggleStatus(teacher),
    );
  }
}
