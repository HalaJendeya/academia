import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_destructive_button.dart';
import '../../../core/widgets/app_menu_tile.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/admin_access_guard.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.logout();
    if (context.mounted) {
      if (success) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? AppStrings.logoutFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
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
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProfile = authProvider.currentUserProfile;
    final adminName = userProfile?.fullName ?? AppStrings.adminRoleLabel;
    final adminEmail = userProfile?.email ?? '';

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.settingsTitle),
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
              // Admin Summary Card
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adminName,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            adminEmail,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),

              // Account Information Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.accountInformation,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: AppSpacing.small),
                    _buildInfoRow(
                      Icons.person_outline_rounded,
                      AppStrings.profileTitleAdmin,
                      AppStrings.adminRoleValue,
                    ),
                    _buildInfoRow(
                      Icons.email_outlined,
                      AppStrings.studentEmailLabel,
                      adminEmail,
                    ),
                    _buildInfoRow(
                      Icons.security_rounded,
                      AppStrings.accountStatusLabel,
                      AppStrings.accountStatusValue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),

              // Menu Options Card
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    /*
                     * الهيكل الأكاديمي مرتَّب باتجاه الاعتماد: القسم يملك
                     * التخصص، والتخصص يملك خطته الدراسية، والفصول الدراسية
                     * إطار زمني مستقل عنها.
                     */
                    AppMenuTile(
                      icon: Icons.account_tree_rounded,
                      title: AppStrings.departmentsManagementTitle,
                      subtitle: AppStrings.departmentsTileDesc,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.adminDepartments);
                      },
                    ),
                    AppMenuTile(
                      icon: Icons.school_rounded,
                      title: AppStrings.majorsManagementTitle,
                      subtitle: AppStrings.majorsTileDesc,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.adminMajors);
                      },
                    ),
                    AppMenuTile(
                      icon: Icons.list_alt_rounded,
                      title: AppStrings.curriculumManagementTitle,
                      subtitle: AppStrings.curriculumTileDesc,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.adminCurriculum);
                      },
                    ),
                    // إعداد أكاديمي على مستوى النظام: إنشاء الفصول الدراسية
                    // وتحديد الفصل الحالي الذي تعتمد عليه شاشات الطروحات.
                    AppMenuTile(
                      icon: Icons.event_note_rounded,
                      title: AppStrings.semestersManagementTitle,
                      subtitle: AppStrings.semestersTileDesc,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.adminSemesters);
                      },
                    ),
                    AppMenuTile(
                      icon: Icons.help_outline_rounded,
                      title: AppStrings.helpSupportTitle,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.helpSupport);
                      },
                    ),
                    AppMenuTile(
                      icon: Icons.info_outline_rounded,
                      title: AppStrings.appInformationTitle,
                      subtitle: AppStrings.appVersionValue,
                      showDivider: false,
                      enabled: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.extraLarge),

              // Logout Button
              AppDestructiveButton(
                label: AppStrings.logout,
                onPressed: () => _handleLogout(context),
                icon: Icons.logout_rounded,
              ),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }
}
