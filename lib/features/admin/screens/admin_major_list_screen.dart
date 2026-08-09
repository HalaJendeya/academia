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
import '../../academics/models/major_model.dart';
import '../../academics/providers/academic_structure_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// التخصصات (البرامج الدراسية). كل تخصص ينتمي إلى قسم وله خطة دراسية.
///
/// لا يوجد حذف نهائي — الأرشفة هي الإزالة المعتمدة، لأن حذف تخصص يترك
/// صفوف خطته الدراسية بلا مرجع.
class AdminMajorListScreen extends StatefulWidget {
  const AdminMajorListScreen({super.key});

  @override
  State<AdminMajorListScreen> createState() => _AdminMajorListScreenState();
}

class _AdminMajorListScreenState extends State<AdminMajorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicStructureProvider>().listenToStructure();
    });
  }

  void _showArchiveDialog(BuildContext context, MajorModel major) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          AppStrings.archiveMajorTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          '${AppStrings.archiveMajorConfirm}\n(${major.name})',
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
                final success = await provider.updateMajor(
                  major.copyWith(status: MajorModel.statusArchived),
                );

                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  success
                      ? const SnackBar(
                          content: Text(AppStrings.majorArchivedSuccess),
                        )
                      : SnackBar(
                          content: Text(
                            provider.errorMessage ?? AppStrings.majorSaveError,
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
          title: const Text(AppStrings.majorsManagementTitle),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.adminAddMajor);
          },
          label: const Text(AppStrings.addMajorLabel),
          icon: const Icon(Icons.add_rounded),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(AcademicStructureProvider provider) {
    if (provider.isLoading && provider.majors.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.errorMessage != null && provider.majors.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () => provider.listenToStructure(),
      );
    }

    if (provider.majors.isEmpty) {
      return AppEmptyState(
        title: AppStrings.noMajorsFound,
        description: AppStrings.noMajorsDesc,
        icon: Icons.school_rounded,
        actionLabel: AppStrings.addMajorLabel,
        onAction: () {
          Navigator.of(context).pushNamed(AppRoutes.adminAddMajor);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.medium),
      itemCount: provider.majors.length,
      itemBuilder: (context, index) =>
          _buildMajorCard(provider.majors[index], provider),
    );
  }

  Widget _buildMajorCard(MajorModel major, AcademicStructureProvider provider) {
    final statusColor = major.isActive
        ? AppColors.activeStatus
        : AppColors.textMuted;

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
                  major.name,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: major.isActive
                    ? AppStrings.activeStatus
                    : AppStrings.archivedStatus,
                backgroundColor: statusColor.withValues(alpha: 0.08),
                foregroundColor: statusColor,
              ),
            ],
          ),
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
                major.code,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Icon(
                Icons.account_tree_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  provider.departmentNameFor(major.departmentId),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              const Icon(
                Icons.layers_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${major.totalLevels} ${AppStrings.levelsSuffix}',
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
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.adminCurriculum, arguments: major);
                },
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: const Text(AppStrings.curriculumManagementTitle),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                tooltip: AppStrings.editAction,
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.adminAddMajor, arguments: major);
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.archive_rounded,
                  color: major.isActive
                      ? AppColors.secondary
                      : AppColors.textDisabled,
                ),
                tooltip: AppStrings.archiveAction,
                onPressed: major.isActive
                    ? () => _showArchiveDialog(context, major)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
