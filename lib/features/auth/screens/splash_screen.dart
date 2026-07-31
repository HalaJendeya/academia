import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

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
    _startRoutingTimer();
  }

  Future<void> _startRoutingTimer() async {
    // Show splash screen for 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAccount = prefs.getBool('has_account') ?? false;

      final auth = widget.auth ?? FirebaseAuth.instance;
      final isLoggedIn = auth.currentUser != null;

      if (!mounted) return;

      if (hasAccount) {
        if (isLoggedIn) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.welcome);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.welcome);
      }
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
