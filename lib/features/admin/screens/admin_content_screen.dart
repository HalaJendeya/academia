import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_menu_tile.dart';
import '../widgets/admin_access_guard.dart';

class AdminContentScreen extends StatelessWidget {
  const AdminContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.contentManagementTitle),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Informative Hero Header
              AppCard(
                backgroundColor: AppColors.secondary.withValues(alpha: 0.05),
                borderColor: AppColors.secondary.withValues(alpha: 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.contentManagementCenter,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.contentManagementDesc,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),

              // Menu navigation tiles
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    AppMenuTile(
                      title: AppStrings.announcementsManagementTitle,
                      subtitle: AppStrings.announcementsTileDesc,
                      icon: Icons.campaign_rounded,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.adminAnnouncements);
                      },
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    AppMenuTile(
                      title: AppStrings.reportedPostsTitle,
                      subtitle: AppStrings.reportedPostsTileDesc,
                      icon: Icons.report_problem_rounded,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.adminReportedPosts);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
