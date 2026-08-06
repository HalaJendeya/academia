import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  final FirebaseAuth? auth;

  const SplashScreen({super.key, this.auth});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startRouting();
  }

  Future<void> _startRouting() async {
    // Show splash screen for 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await _resolveInitialRoute();
  }

  Future<void> _resolveInitialRoute() async {
    try {
      final authProvider = context.read<AuthProvider>();

      final initialized = await authProvider.initializeCurrentUser();

      if (!mounted) return;

      if (!initialized || !authProvider.isLoggedIn) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
        return;
      }

      if (!authProvider.isAccountActive) {
        await authProvider.logout();

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
        return;
      }

      // Admin must be checked before student verification.
      if (authProvider.isAdmin) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.adminShell,
          (route) => false,
        );
        return;
      }

      final auth = widget.auth ?? FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user == null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
        return;
      }

      try {
        await user.reload();
      } catch (_) {
        // Continue with the locally available authentication state if offline.
      }

      if (!mounted) return;

      final refreshedUser = auth.currentUser;

      if (refreshedUser == null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
        return;
      }

      // Email verification applies only to students.
      if (!refreshedUser.emailVerified) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.studentVerification,
          (route) => false,
          arguments: refreshedUser.email,
        );
        return;
      }

      final onboardingProvider = context.read<OnboardingProvider>();

      onboardingProvider.initializeForUser(refreshedUser.uid);

      final onboardingCompleted =
          authProvider.onboardingCompleted ||
          await onboardingProvider.checkOnboardingCompleted();

      if (!mounted) return;

      if (onboardingCompleted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.onboardingWelcome,
          (route) => false,
        );
      }
    } catch (_) {
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashGradientTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AppAssets.logo, width: AppSizes.splashLogoWidth),
                const SizedBox(height: AppSpacing.large),
                const Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.splashTitle,
                ),
                const SizedBox(height: AppSpacing.small),
                const Text(
                  AppStrings.splashSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.splashSubtitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
