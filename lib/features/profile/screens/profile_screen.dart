import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_destructive_button.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_menu_tile.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/error_state.dart';
import '../models/student_profile.dart';
import '../providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  void _handleNavigation(int index) {
    handleMainNavigation(context, index, currentIndex: 4);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    if (profileProvider.isLoading && profileProvider.profile == null) {
      return AuthenticatedPageScaffold(
        currentIndex: 4,
        onNavigationTap: _handleNavigation,
        appBar: const AcademiaMainAppBar(
          title: AppStrings.profileTitle,
          showProfile: false,
          showSearch: false,
          showNotifications: false,
        ),
        body: const AppLoadingState(message: AppStrings.loadingProfileData),
      );
    }

    if (profileProvider.errorMessage != null &&
        profileProvider.profile == null) {
      return AuthenticatedPageScaffold(
        currentIndex: 4,
        onNavigationTap: _handleNavigation,
        appBar: const AcademiaMainAppBar(
          title: AppStrings.profileTitle,
          showProfile: false,
          showSearch: false,
          showNotifications: false,
        ),
        body: AppErrorState(
          message: profileProvider.errorMessage!,
          onRetry: () {
            context.read<ProfileProvider>().loadProfile(forceRefresh: true);
          },
        ),
      );
    }

    final profile = profileProvider.profile;
    if (profile == null) {
      return AuthenticatedPageScaffold(
        currentIndex: 4,
        onNavigationTap: _handleNavigation,
        appBar: const AcademiaMainAppBar(
          title: AppStrings.profileTitle,
          showProfile: false,
          showSearch: false,
          showNotifications: false,
        ),
        body: AppErrorState(
          message: AppStrings.profileNotFound,
          onRetry: () {
            context.read<ProfileProvider>().loadProfile(forceRefresh: true);
          },
        ),
      );
    }

    return AuthenticatedPageScaffold(
      currentIndex: 4,
      onNavigationTap: _handleNavigation,
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
              _buildSummaryCard(context, profileProvider, profile),
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

  Widget _buildSummaryCard(
    BuildContext context,
    ProfileProvider profileProvider,
    StudentProfile profile,
  ) {
    final displayName = profile.fullName.trim().isEmpty
        ? AppStrings.profileNameUnavailable
        : profile.fullName;
    final displayEmail = profile.email.trim().isEmpty
        ? AppStrings.profileEmailUnavailable
        : profile.email;

    return AppCard(
      child: Row(
        children: [
          // Circular avatar on the far right (index 0 in RTL)
          Semantics(
            label: AppStrings.studentAvatarSemantics,
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              backgroundImage: profileProvider.localPhotoBytes != null
                  ? MemoryImage(profileProvider.localPhotoBytes!)
                  : (profile.photoUrl != null &&
                        profile.photoUrl!.trim().isNotEmpty)
                  ? NetworkImage(profile.photoUrl!) as ImageProvider
                  : null,
              child:
                  (profileProvider.localPhotoBytes != null ||
                      (profile.photoUrl != null &&
                          profile.photoUrl!.trim().isNotEmpty))
                  ? null
                  : const Icon(
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
                  displayName,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayEmail,
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
              Navigator.pushNamed(context, AppRoutes.editProfile);
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
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.profileNotificationSettings,
              );
            },
          ),
          AppMenuTile(
            icon: Icons.tune_rounded,
            iconBackgroundColor: AppColors.primary.withValues(alpha: 0.08),
            iconColor: AppColors.primary,
            title: AppStrings.studyPreferencesTitle,
            subtitle: AppStrings.studyPreferencesSubtitle,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.studyPreferences);
            },
          ),
          // TODO: product review requested on analytics subtitle mismatch with storage/download management
          AppMenuTile(
            icon: Icons.analytics_outlined,
            iconBackgroundColor: AppColors.warning.withValues(alpha: 0.08),
            iconColor: AppColors.warning,
            title: AppStrings.analyticsDashboardTitle,
            subtitle: AppStrings.analyticsDashboardSubtitle,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.profileAnalytics);
            },
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
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.helpSupport);
            },
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
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_right_rounded,
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return AppDestructiveButton(
      label: AppStrings.logout,
      icon: isRtl
          ? Transform.scale(
              scaleX: -1,
              child: const Icon(
                Icons.logout_rounded,
                size: 20,
                color: AppColors.danger,
              ),
            )
          : Icons.logout_rounded,
      filled: false,
      onPressed: () {
        _showLogoutDialog(context);
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    bool isLoggingOut = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  onPressed: isLoggingOut
                      ? null
                      : () async {
                          setDialogState(() {
                            isLoggingOut = true;
                          });

                          final authProvider = context.read<AuthProvider>();

                          final navigator = Navigator.of(context);

                          final success = await authProvider.logout();

                          if (!success) {
                            if (!context.mounted) {
                              return;
                            }

                            setDialogState(() {
                              isLoggingOut = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  authProvider.errorMessage ??
                                      AppStrings.errorUnknown,
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );

                            return;
                          }

                          final preferences =
                              await SharedPreferences.getInstance();

                          await preferences.setBool('has_account', false);

                          if (!context.mounted) {
                            return;
                          }

                          navigator.pushNamedAndRemoveUntil(
                            AppRoutes.login,
                            (route) => false,
                          );
                        },
                  child: isLoggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(AppStrings.logoutConfirmAction),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  onPressed: isLoggingOut
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text(AppStrings.cancel),
                ),
              ],
            );
          },
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
