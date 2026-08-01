import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/preference_switch_tile.dart';
import '../providers/onboarding_provider.dart';

class NotificationPreferencesSetupScreen extends StatefulWidget {
  const NotificationPreferencesSetupScreen({super.key});

  @override
  State<NotificationPreferencesSetupScreen> createState() =>
      _NotificationPreferencesSetupScreenState();
}

class _NotificationPreferencesSetupScreenState
    extends State<NotificationPreferencesSetupScreen> {
  Future<void> _handleSave() async {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    if (provider.isLoading) return;

    final success = await provider.completeOnboarding();

    if (success && mounted) {
      Navigator.pushNamed(context, AppRoutes.setupComplete);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? AppStrings.onboardingSaveError,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleBack() {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    if (!provider.isLoading) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final isLoading = onboardingProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.notificationPreferencesTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: isLoading ? null : _handleBack,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Header description text
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Text(
                AppStrings.notificationPreferencesDescription,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            // Preference toggle tiles list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                children: [
                  PreferenceSwitchTile(
                    icon: Icons.assignment_outlined,
                    iconContainerColor: AppColors.secondary,
                    title: AppStrings.taskRemindersTitle,
                    description: AppStrings.taskRemindersDescription,
                    value: onboardingProvider.taskReminders,
                    onChanged: isLoading
                        ? (_) {}
                        : (val) => onboardingProvider.setTaskReminders(val),
                  ),
                  PreferenceSwitchTile(
                    icon: Icons.groups_outlined,
                    iconContainerColor: AppColors.primary,
                    title: AppStrings.studySessionRemindersTitle,
                    description: AppStrings.studySessionRemindersDescription,
                    value: onboardingProvider.studySessionReminders,
                    onChanged: isLoading
                        ? (_) {}
                        : (val) =>
                              onboardingProvider.setStudySessionReminders(val),
                  ),
                  PreferenceSwitchTile(
                    icon: Icons.calendar_month_outlined,
                    iconContainerColor: AppColors.error,
                    title: AppStrings.deadlineRemindersTitle,
                    description: AppStrings.deadlineRemindersDescription,
                    value: onboardingProvider.deadlineReminders,
                    onChanged: isLoading
                        ? (_) {}
                        : (val) => onboardingProvider.setDeadlineReminders(val),
                  ),
                  PreferenceSwitchTile(
                    icon: Icons.description_outlined,
                    iconContainerColor: AppColors.primaryDarker,
                    title: AppStrings.dailySummaryTitle,
                    description: AppStrings.dailySummaryDescription,
                    value: onboardingProvider.dailySummary,
                    onChanged: isLoading
                        ? (_) {}
                        : (val) => onboardingProvider.setDailySummary(val),
                  ),
                  PreferenceSwitchTile(
                    icon: Icons.menu_book_outlined,
                    iconContainerColor: AppColors.textSecondary,
                    title: AppStrings.courseNotificationsTitle,
                    description: AppStrings.courseNotificationsDescription,
                    value: onboardingProvider.courseNotifications,
                    onChanged: isLoading
                        ? (_) {}
                        : (val) =>
                              onboardingProvider.setCourseNotifications(val),
                  ),
                ],
              ),
            ),
            // Save Button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _handleSave,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                label: isLoading
                    ? const Text('...')
                    : const Text(AppStrings.savePreferences),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
