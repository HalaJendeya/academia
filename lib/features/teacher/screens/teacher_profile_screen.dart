import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_destructive_button.dart';
import '../../auth/providers/auth_provider.dart';

/// الملف الشخصي للمعلّم.
///
/// يقرأ النموذج المحمَّل في AuthProvider — لا خدمة ولا مزوّد ملف شخصي
/// جديد. ProfileScreen الحالية لا تصلح هنا: هي مبنية على StudentProfile
/// وتحمل شريط تنقّل الطالب داخلها.
class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.logout();
    if (!context.mounted) return;

    if (success) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      return;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? AppStrings.logoutFailed),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().currentUserProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.teacherProfileTitle),
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
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.co_present_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.fullName ?? AppStrings.notProvidedValue,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile?.email ?? AppStrings.notProvidedValue,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.extraLarge),
            AppDestructiveButton(
              label: AppStrings.logout,
              onPressed: () => _handleLogout(context),
              icon: Icons.logout_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
