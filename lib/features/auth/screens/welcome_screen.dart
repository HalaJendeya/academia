import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Top Logo & App Title
              Center(
                child: Image.asset(
                  AppAssets.logo,
                  height: 44,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 48),
              // Center Welcome Graphic Illustration
              Center(
                child: Image.asset(
                  AppAssets.welcomeIllustration,
                  height: 280,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 48),
              // Main Title
              const Text(
                AppStrings.welcomeHeading,
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.medium),
              // Subtitle
              Text(
                AppStrings.welcomeSubtitleText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Primary and Secondary Action Buttons
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.register),
                child: const Text(AppStrings.createAccount),
              ),
              const SizedBox(height: AppSpacing.medium),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                child: const Text(AppStrings.welcomeAlreadyHaveAccount),
              ),
              const SizedBox(height: 32),
              // Footnote Caption
              Text(
                AppStrings.welcomeFootnote,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
