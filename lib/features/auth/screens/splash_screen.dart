import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashGradientTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppAssets.logo,
                  width: AppSizes.splashLogoWidth,
                ),
                const SizedBox(
                  height: AppSpacing.large,
                ),
                const Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.splashTitle,
                ),
                const SizedBox(
                  height: AppSpacing.small,
                ),
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