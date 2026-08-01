import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  bool _isNavigating = false;

  void _navigateToSetup() {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });

    // Ensure provider is initialized for current user UID
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      Provider.of<OnboardingProvider>(
        context,
        listen: false,
      ).initializeForUser(uid);
    }

    Navigator.pushNamed(context, AppRoutes.studyDaysSetup).then((_) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  Future<void> _skipOnboarding() async {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      provider.initializeForUser(uid);
    }

    final success = await provider.skipOnboarding();
    if (success && mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? AppStrings.onboardingSkipError,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final isLoading = onboardingProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              // Centered Icon inside a circular light-blue container
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withValues(alpha: 0.12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 64,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Main title
              Text(
                AppStrings.onboardingWelcomeTitle,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.medium),
              // Description
              Text(
                AppStrings.onboardingWelcomeDescription,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              // Buttons
              ElevatedButton(
                onPressed: (isLoading || _isNavigating)
                    ? null
                    : _navigateToSetup,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.arrow_back, // Represents forward in RTL direction
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(AppStrings.startSetup),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              OutlinedButton(
                onPressed: (isLoading || _isNavigating)
                    ? null
                    : _skipOnboarding,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text(AppStrings.skipForNow),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
