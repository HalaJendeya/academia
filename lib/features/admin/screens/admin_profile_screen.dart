import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../widgets/admin_back_button.dart';
import '../../auth/providers/auth_provider.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  Widget _buildProfileField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.currentUserProfile;

    final name = profile?.fullName ?? '';
    final email = profile?.email ?? '';
    final role = AppStrings.platformRoleAdminValue;
    final status = AppStrings.activeStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileTitleAdmin),
        leading: const AdminBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          children: [
            // Avatar and Name Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.secondary.withValues(
                      alpha: 0.08,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 64,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    name,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.extraLarge),

            // Profile info card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.adminPersonalInfoTitle,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: AppSpacing.medium),
                  _buildProfileField(
                    AppStrings.fullNameLabel,
                    name,
                    Icons.person_rounded,
                  ),
                  _buildProfileField(
                    AppStrings.studentEmailLabel,
                    email,
                    Icons.email_rounded,
                  ),
                  _buildProfileField(
                    AppStrings.platformRoleLabel,
                    role,
                    Icons.admin_panel_settings_rounded,
                  ),
                  _buildProfileField(
                    AppStrings.statusLabel,
                    status,
                    Icons.check_circle_outline_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
