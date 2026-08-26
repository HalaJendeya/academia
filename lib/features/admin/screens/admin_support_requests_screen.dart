import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../profile/models/support_request.dart';
import '../providers/admin_support_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';
import '../widgets/support_request_details_dialog.dart';

/// صندوق وارد طلبات الدعم.
///
/// قراءة ومتابعة فقط: الطلبات تُنشأ من شاشة المساعدة لدى الطالب، وهذه
/// الشاشة تعرضها وتنقل حالتها بين مفتوح ومحلول. لا رد ولا مراسلة.
class AdminSupportRequestsScreen extends StatefulWidget {
  const AdminSupportRequestsScreen({super.key});

  @override
  State<AdminSupportRequestsScreen> createState() =>
      _AdminSupportRequestsScreenState();
}

class _AdminSupportRequestsScreenState
    extends State<AdminSupportRequestsScreen> {
  SupportRequestFilter _filter = SupportRequestFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminSupportProvider>().listenToRequests();
    });
  }

  Future<void> _openDetails(SupportRequest request) async {
    final provider = context.read<AdminSupportProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final action = await SupportRequestDetailsDialog.show(context, request);
    if (action == null || !mounted) return;

    final resolving = action == SupportRequestAction.markResolved;
    final success = resolving
        ? await provider.markResolved(request.id)
        : await provider.reopen(request.id);

    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      success
          ? SnackBar(
              content: Text(
                resolving
                    ? AppStrings.supportRequestResolvedSuccess
                    : AppStrings.supportRequestReopenedSuccess,
              ),
            )
          : SnackBar(
              content: Text(
                provider.errorMessage ?? AppStrings.supportRequestStatusError,
              ),
              backgroundColor: AppColors.error,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminSupportProvider>();

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.supportRequestsTitle),
          leading: const AdminBackButton(),
        ),
        body: Column(
          children: [
            _buildFilterBar(provider),
            Expanded(child: _buildBody(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(AdminSupportProvider provider) {
    // العدّادات مشتقة من القائمة المحمَّلة، ولا تُعرض قبل وصولها.
    final hasData = !provider.isLoading && provider.errorMessage == null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.small,
      ),
      child: Row(
        children: [
          _buildFilterChip(
            AppStrings.supportFilterAll,
            SupportRequestFilter.all,
            hasData ? provider.requests.length : null,
          ),
          const SizedBox(width: AppSpacing.small),
          _buildFilterChip(
            AppStrings.supportFilterOpen,
            SupportRequestFilter.open,
            hasData ? provider.openRequests.length : null,
          ),
          const SizedBox(width: AppSpacing.small),
          _buildFilterChip(
            AppStrings.supportFilterResolved,
            SupportRequestFilter.resolved,
            hasData ? provider.resolvedRequests.length : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    SupportRequestFilter value,
    int? count,
  ) {
    final isSelected = _filter == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = value),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            count == null ? label : '$label ($count)',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AdminSupportProvider provider) {
    if (provider.isLoading) return const AppLoadingState();

    // الخطأ محصور في هذه الشاشة، ويعيد المحاولة دون مغادرتها.
    if (provider.errorMessage != null) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: () {
          provider.clearError();
          provider.listenToRequests();
        },
      );
    }

    if (provider.requests.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.supportRequestsEmptyTitle,
        description: AppStrings.supportRequestsEmptyDesc,
        icon: Icons.support_agent_rounded,
      );
    }

    final visible = provider.filtered(_filter);

    // قائمة فارغة بسبب التصفية رسالتها غير رسالة صندوق وارد فارغ.
    if (visible.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.supportRequestsEmptyFilteredTitle,
        description: AppStrings.supportRequestsEmptyFilteredDesc,
        icon: Icons.filter_list_off_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.small,
        AppSpacing.screenHorizontal,
        AppSpacing.huge,
      ),
      itemCount: visible.length,
      itemBuilder: (context, index) => _buildRequestCard(visible[index]),
    );
  }

  Widget _buildRequestCard(SupportRequest request) {
    final isOpen = request.isOpen;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      onTap: () => _openDetails(request),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  SupportRequestDetailsDialog.orUnknown(request.subject),
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              AppStatusBadge(
                label: isOpen
                    ? AppStrings.supportStatusOpen
                    : AppStrings.supportStatusResolved,
                backgroundColor:
                    (isOpen ? AppColors.warning : AppColors.activeStatus)
                        .withValues(alpha: 0.12),
                foregroundColor: isOpen
                    ? AppColors.warningDark
                    : AppColors.activeStatus,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            SupportRequestDetailsDialog.orUnknown(request.fullName),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            SupportRequestDetailsDialog.orUnknown(request.message),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            SupportRequestDetailsDialog.formatDate(request.createdAt),
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
