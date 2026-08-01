import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/study_day_chip.dart';
import '../providers/onboarding_provider.dart';

class StudyDaysSetupScreen extends StatefulWidget {
  const StudyDaysSetupScreen({super.key});

  @override
  State<StudyDaysSetupScreen> createState() => _StudyDaysSetupScreenState();
}

class _StudyDaysSetupScreenState extends State<StudyDaysSetupScreen> {
  bool _isNavigating = false;

  void _handleNext() {
    if (_isNavigating) return;

    final provider = Provider.of<OnboardingProvider>(context, listen: false);

    if (provider.studyDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.selectAtLeastOneStudyDay),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    Navigator.pushNamed(context, AppRoutes.sessionDurationSetup).then((_) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  void _handleBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final selectedDays = onboardingProvider.studyDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top App Name
            const SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Header Page Title and Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                children: [
                  Text(
                    AppStrings.studyDaysTitle,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.studyDaysDescription,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Day Selection Container
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  children: [
                    // Saturday and Sunday
                    Row(
                      children: [
                        Expanded(
                          child: StudyDayChip(
                            label: AppStrings.saturday,
                            isSelected: selectedDays.contains(
                              AppStrings.saturday,
                            ),
                            onTap: () => onboardingProvider.toggleStudyDay(
                              AppStrings.saturday,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StudyDayChip(
                            label: AppStrings.sunday,
                            isSelected: selectedDays.contains(
                              AppStrings.sunday,
                            ),
                            onTap: () => onboardingProvider.toggleStudyDay(
                              AppStrings.sunday,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Monday and Tuesday
                    Row(
                      children: [
                        Expanded(
                          child: StudyDayChip(
                            label: AppStrings.monday,
                            isSelected: selectedDays.contains(
                              AppStrings.monday,
                            ),
                            onTap: () => onboardingProvider.toggleStudyDay(
                              AppStrings.monday,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StudyDayChip(
                            label: AppStrings.tuesday,
                            isSelected: selectedDays.contains(
                              AppStrings.tuesday,
                            ),
                            onTap: () => onboardingProvider.toggleStudyDay(
                              AppStrings.tuesday,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Wednesday and Thursday
                    Row(
                      children: [
                        Expanded(
                          child: StudyDayChip(
                            label: AppStrings.wednesday,
                            isSelected: selectedDays.contains(
                              AppStrings.wednesday,
                            ),
                            onTap: () => onboardingProvider.toggleStudyDay(
                              AppStrings.wednesday,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StudyDayChip(
                            label: AppStrings.thursday,
                            isSelected: selectedDays.contains(
                              AppStrings.thursday,
                            ),
                            onTap: () => onboardingProvider.toggleStudyDay(
                              AppStrings.thursday,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Friday (Full-width spanning)
                    Row(
                      children: [
                        Expanded(
                          child: StudyDayChip(
                            label: AppStrings.friday,
                            isSelected: selectedDays.contains(
                              AppStrings.friday,
                            ),
                            onTap: () => onboardingProvider.toggleStudyDay(
                              AppStrings.friday,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Action buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _handleNext,
                    child: const Text(AppStrings.next),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  OutlinedButton(
                    onPressed: _handleBack,
                    child: const Text(AppStrings.back),
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
