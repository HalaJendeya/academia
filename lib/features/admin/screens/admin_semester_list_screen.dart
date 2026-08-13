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
import '../../semesters/models/semester_model.dart';
import '../../semesters/providers/semester_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

class AdminSemesterListScreen extends StatefulWidget {
  const AdminSemesterListScreen({super.key});

  @override
  State<AdminSemesterListScreen> createState() =>
      _AdminSemesterListScreenState();
}

class _AdminSemesterListScreenState extends State<AdminSemesterListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SemesterProvider>().listenToSemesters();
    });
  }

  ({String label, Color color}) _statusPresentation(SemesterModel semester) {
    if (semester.isCurrent) {
      return (
        label: AppStrings.semesterStatusCurrent,
        color: AppColors.activeStatus,
      );
    }
    if (semester.isUpcoming) {
      return (
        label: AppStrings.semesterStatusUpcoming,
        color: AppColors.primary,
      );
    }
    return (
      label: AppStrings.semesterStatusCompleted,
      color: AppColors.textMuted,
    );
  }

  void _showSetCurrentDialog(BuildContext context, SemesterModel semester) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          AppStrings.setCurrentSemesterTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          '${AppStrings.setCurrentSemesterConfirm}\n(${semester.semesterName})',
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

                final provider = context.read<SemesterProvider>();
                final success = await provider.setCurrentSemester(semester.id);

                if (!mounted) return;

                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.semesterSetAsCurrentSuccess),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? AppStrings.semesterSaveError,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SemesterProvider>();

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.semestersManagementTitle),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.adminAddSemester);
          },
          label: const Text(AppStrings.addSemesterLabel),
          icon: const Icon(Icons.add_rounded),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(SemesterProvider provider) {
    if (provider.isLoading) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.semesters.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () => provider.listenToSemesters(),
      );
    }

    if (provider.semesters.isEmpty) {
      return AppEmptyState(
        title: AppStrings.noSemestersFound,
        description: AppStrings.noSemestersDesc,
        icon: Icons.event_note_rounded,
        actionLabel: AppStrings.addSemesterLabel,
        onAction: () {
          Navigator.of(context).pushNamed(AppRoutes.adminAddSemester);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.medium),
      itemCount: provider.semesters.length,
      itemBuilder: (context, index) {
        return _buildSemesterCard(provider.semesters[index], provider);
      },
    );
  }

  Widget _buildSemesterCard(SemesterModel semester, SemesterProvider provider) {
    final presentation = _statusPresentation(semester);

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
                  semester.semesterName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: presentation.label,
                backgroundColor: presentation.color.withValues(alpha: 0.08),
                foregroundColor: presentation.color,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${AppStrings.academicYearOnlyLabel}: ${semester.academicYear}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Icon(
                Icons.numbers_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${AppStrings.semesterNumberLabel}: ${semester.semesterNumber}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.divider),
          Row(
            children: [
              TextButton.icon(
                onPressed: provider.isSaving || semester.isCurrent
                    ? null
                    : () => _showSetCurrentDialog(context, semester),
                icon: const Icon(Icons.event_available_rounded, size: 18),
                label: const Text(AppStrings.setAsCurrentAction),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                tooltip: AppStrings.editAction,
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.adminAddSemester, arguments: semester);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
