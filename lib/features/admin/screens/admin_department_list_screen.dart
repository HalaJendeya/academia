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
import '../../academics/models/department_model.dart';
import '../../academics/providers/academic_structure_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// الأقسام الأكاديمية: الوحدة التي تملك المساقات وتنتمي إليها التخصصات.
///
/// لا يوجد حذف نهائي — الأرشفة هي الإزالة المعتمدة، لأن حذف قسم يترك
/// مساقاته وتخصصاته بلا مرجع.
class AdminDepartmentListScreen extends StatefulWidget {
  const AdminDepartmentListScreen({super.key});

  @override
  State<AdminDepartmentListScreen> createState() =>
      _AdminDepartmentListScreenState();
}

class _AdminDepartmentListScreenState extends State<AdminDepartmentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicStructureProvider>().listenToStructure();
    });
  }

  void _showArchiveDialog(BuildContext context, DepartmentModel department) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          AppStrings.archiveDepartmentTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          '${AppStrings.archiveDepartmentConfirm}\n(${department.name})',
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

                final provider = context.read<AcademicStructureProvider>();
                final success = await provider.updateDepartment(
                  department.copyWith(status: DepartmentModel.statusArchived),
                );

                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  success
                      ? const SnackBar(
                          content: Text(AppStrings.departmentArchivedSuccess),
                        )
                      : SnackBar(
                          content: Text(
                            provider.errorMessage ??
                                AppStrings.departmentSaveError,
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
    final provider = context.watch<AcademicStructureProvider>();

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.departmentsManagementTitle),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.adminAddDepartment);
          },
          label: const Text(AppStrings.addDepartmentLabel),
          icon: const Icon(Icons.add_rounded),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(AcademicStructureProvider provider) {
    if (provider.isLoading && provider.departments.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.departments.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () => provider.listenToDepartments(),
      );
    }

    if (provider.departments.isEmpty) {
      return AppEmptyState(
        title: AppStrings.noDepartmentsFound,
        description: AppStrings.noDepartmentsDesc,
        icon: Icons.account_tree_rounded,
        actionLabel: AppStrings.addDepartmentLabel,
        onAction: () {
          Navigator.of(context).pushNamed(AppRoutes.adminAddDepartment);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.medium),
      itemCount: provider.departments.length,
      itemBuilder: (context, index) =>
          _buildDepartmentCard(provider.departments[index], provider),
    );
  }

  Widget _buildDepartmentCard(
    DepartmentModel department,
    AcademicStructureProvider provider,
  ) {
    final statusColor = department.isActive
        ? AppColors.activeStatus
        : AppColors.textMuted;
    final majorCount = provider.majorsOfDepartment(department.id).length;

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
                  department.name,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: department.isActive
                    ? AppStrings.activeStatus
                    : AppStrings.archivedStatus,
                backgroundColor: statusColor.withValues(alpha: 0.08),
                foregroundColor: statusColor,
              ),
            ],
          ),
          if (department.code.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Row(
              children: [
                const Icon(
                  Icons.tag_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  department.code,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Icon(
                Icons.school_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${AppStrings.majorsManagementTitle}: $majorCount',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                tooltip: AppStrings.editAction,
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.adminAddDepartment,
                    arguments: department,
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.archive_rounded,
                  color: department.isActive
                      ? AppColors.secondary
                      : AppColors.textDisabled,
                ),
                tooltip: AppStrings.archiveAction,
                onPressed: department.isActive
                    ? () => _showArchiveDialog(context, department)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
