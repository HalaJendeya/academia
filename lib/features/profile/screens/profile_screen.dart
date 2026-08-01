import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_destructive_button.dart';
import '../../../core/widgets/app_menu_tile.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthenticatedPageScaffold(
      currentIndex: 4,
      onNavigationTap: (index) {
        handleMainNavigation(context, index, currentIndex: 4);
      },
      appBar: const AcademiaMainAppBar(
        title: AppStrings.profileTitle,
        showProfile: false,
        showSearch: false,
        showNotifications: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Student summary card
              _buildSummaryCard(context),
              const SizedBox(height: AppSpacing.large),
              // First settings section
              _buildFirstSection(context),
              const SizedBox(height: AppSpacing.large),
              // Second settings section
              _buildSecondSection(context),
              const SizedBox(height: AppSpacing.extraLarge),
              // Logout button
              _buildLogoutButton(context),
              // Additional bottom padding to prevent navigation overlay clipping
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          // Circular avatar on the far right (index 0 in RTL)
          Semantics(
            label: 'الصورة الشخصية للطالب',
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.secondary,
                size: 40,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          // Student details in the middle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.mockProfileName,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.mockProfileEmail,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          // Edit button on the far left
          IconButton(
            tooltip: AppStrings.editProfileTooltip,
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
            onPressed: () {
              _showUnderDevelopmentSnackBar(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFirstSection(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppMenuTile(
            icon: Icons.notifications_none_rounded,
            iconBackgroundColor: AppColors.secondary.withValues(alpha: 0.08),
            iconColor: AppColors.secondary,
            title: AppStrings.notificationSettingsTitle,
            subtitle: AppStrings.notificationSettingsSubtitle,
            onTap: () => _showUnderDevelopmentSnackBar(context),
          ),
          AppMenuTile(
            icon: Icons.tune_rounded,
            iconBackgroundColor: AppColors.primary.withValues(alpha: 0.08),
            iconColor: AppColors.primary,
            title: AppStrings.studyPreferencesTitle,
            subtitle: AppStrings.studyPreferencesSubtitle,
            onTap: () => _showUnderDevelopmentSnackBar(context),
          ),
          // TODO: product review requested on analytics subtitle mismatch with storage/download management
          AppMenuTile(
            icon: Icons.analytics_outlined,
            iconBackgroundColor: AppColors.warning.withValues(alpha: 0.08),
            iconColor: AppColors.warning,
            title: AppStrings.analyticsDashboardTitle,
            subtitle: AppStrings.analyticsDashboardSubtitle,
            onTap: () => _showUnderDevelopmentSnackBar(context),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondSection(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppMenuTile(
            icon: Icons.help_outline_rounded,
            iconBackgroundColor: AppColors.primary.withValues(alpha: 0.08),
            iconColor: AppColors.primary,
            title: AppStrings.helpSupportTitle,
            subtitle: AppStrings.helpSupportSubtitle,
            onTap: () => _showUnderDevelopmentSnackBar(context),
          ),
          AppMenuTile(
            icon: Icons.info_outline_rounded,
            iconBackgroundColor: AppColors.secondary.withValues(alpha: 0.08),
            iconColor: AppColors.secondary,
            title: AppStrings.aboutAppTitle,
            subtitle: AppStrings.aboutAppSubtitle,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.appVersionLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
            onTap: () => _showUnderDevelopmentSnackBar(context),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return AppDestructiveButton(
      label: AppStrings.logout,
      icon: Icons.logout_rounded,
      filled: false,
      onPressed: () {
        _showLogoutDialog(context);
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppStrings.logout, textAlign: TextAlign.right),
          content: const Text(
            AppStrings.logoutConfirmation,
            textAlign: TextAlign.right,
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.logoutLogicComingSoon),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: const Text(AppStrings.logoutConfirmAction),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(AppStrings.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showUnderDevelopmentSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.screenUnderDevelopment),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
