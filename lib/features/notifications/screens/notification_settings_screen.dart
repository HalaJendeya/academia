import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/main_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_preference_switch_tile.dart';
import '../../../core/widgets/app_section.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/authenticated_page_scaffold.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/notification_settings.dart';
import '../providers/notification_settings_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationSettingsProvider>();
      if (!provider.isSaving) {
        provider.loadSettings(forceRefresh: true);
      }
    });
  }

  void _handleNavigation(int index) {
    handleMainNavigation(context, index, currentIndex: 4);
  }

  Future<void> _pickTime(bool isStart, TimeOfDay currentTime) async {
    final provider = context.read<NotificationSettingsProvider>();
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (selectedTime != null) {
      final minutes = selectedTime.hour * 60 + selectedTime.minute;
      if (isStart) {
        provider.setQuietHoursStartMinutes(minutes);
      } else {
        provider.setQuietHoursEndMinutes(minutes);
      }
    }
  }

  void _saveSettings() async {
    final provider = context.read<NotificationSettingsProvider>();
    final success = await provider.saveSettings();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.notificationSettingsSavedSuccessfully),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error =
          provider.errorMessage ?? AppStrings.notificationSettingsSaveError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationSettingsProvider>();
    final settings = provider.settings;

    if (provider.isLoading && settings == null) {
      return AuthenticatedPageScaffold(
        currentIndex: 4,
        onNavigationTap: _handleNavigation,
        appBar: const AcademiaSubAppBar(
          title: AppStrings.notificationSettingsTitle,
        ),
        body: const AppLoadingState(message: AppStrings.loadingProfileData),
      );
    }

    if (provider.errorMessage != null && settings == null) {
      return AuthenticatedPageScaffold(
        currentIndex: 4,
        onNavigationTap: _handleNavigation,
        appBar: const AcademiaSubAppBar(
          title: AppStrings.notificationSettingsTitle,
        ),
        body: AppErrorState(
          message: provider.errorMessage!,
          onRetry: () {
            context.read<NotificationSettingsProvider>().loadSettings(
              forceRefresh: true,
            );
          },
        ),
      );
    }

    if (settings == null) {
      return AuthenticatedPageScaffold(
        currentIndex: 4,
        onNavigationTap: _handleNavigation,
        appBar: const AcademiaSubAppBar(
          title: AppStrings.notificationSettingsTitle,
        ),
        body: AppErrorState(
          message: AppStrings.notificationSettingsNotAvailable,
          onRetry: () {
            context.read<NotificationSettingsProvider>().loadSettings(
              forceRefresh: true,
            );
          },
        ),
      );
    }

    // Convert minutes to TimeOfDay for visual display only
    final startTime = TimeOfDay(
      hour: settings.quietHoursStartMinutes ~/ 60,
      minute: settings.quietHoursStartMinutes % 60,
    );

    final endTime = TimeOfDay(
      hour: settings.quietHoursEndMinutes ~/ 60,
      minute: settings.quietHoursEndMinutes % 60,
    );

    return AuthenticatedPageScaffold(
      currentIndex: 4,
      onNavigationTap: _handleNavigation,
      appBar: const AcademiaSubAppBar(
        title: AppStrings.notificationSettingsTitle,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Card
              _buildHeroCard(),
              const SizedBox(height: AppSpacing.large),

              // 2. General Preferences Section
              _buildGeneralSection(provider, settings),
              const SizedBox(height: AppSpacing.large),

              // 3. Quiet Hours Section
              _buildQuietHoursSection(settings, startTime, endTime),
              const SizedBox(height: AppSpacing.extraLarge),

              // 4. Save Button
              AppPrimaryButton(
                label: AppStrings.saveNotificationSettings,
                isLoading: provider.isSaving,
                isEnabled: provider.hasUnsavedChanges && !provider.isSaving,
                onPressed: _saveSettings,
              ),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return AppCard(
      backgroundColor: AppColors.recommendationBackground,
      borderColor: AppColors.primary.withValues(alpha: 0.15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.small),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Text(
              AppStrings.notificationSettingsHeroTitle,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primaryDarker,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSection(
    NotificationSettingsProvider provider,
    NotificationSettings settings,
  ) {
    return AppSection(
      title: AppStrings.generalNotificationsTitle,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            AppPreferenceSwitchTile(
              title: AppStrings.assignmentRemindersTitle,
              subtitle: AppStrings.assignmentRemindersDescription,
              icon: Icons.assignment_outlined,
              value: settings.assignmentReminders,
              onChanged: provider.setAssignmentReminders,
            ),
            AppPreferenceSwitchTile(
              title: AppStrings.lectureRemindersTitle,
              subtitle: AppStrings.lectureRemindersDescription,
              icon: Icons.event_available_outlined,
              value: settings.lectureReminders,
              onChanged: provider.setLectureReminders,
            ),
            AppPreferenceSwitchTile(
              title: AppStrings.studySessionRemindersSettingsTitle,
              subtitle: AppStrings.studySessionRemindersSettingsDescription,
              icon: Icons.timer_outlined,
              value: settings.studySessionReminders,
              onChanged: provider.setStudySessionReminders,
            ),
            AppPreferenceSwitchTile(
              title: AppStrings.fileNotificationsTitle,
              subtitle: AppStrings.fileNotificationsDescription,
              icon: Icons.insert_drive_file_outlined,
              value: settings.fileNotifications,
              onChanged: provider.setFileNotifications,
            ),
            AppPreferenceSwitchTile(
              title: AppStrings.sharedSpaceNotificationsTitle,
              subtitle: AppStrings.sharedSpaceNotificationsDescription,
              icon: Icons.groups_outlined,
              value: settings.sharedSpaceNotifications,
              onChanged: provider.setSharedSpaceNotifications,
            ),
            AppPreferenceSwitchTile(
              title: AppStrings.dailySummarySettingsTitle,
              subtitle: AppStrings.dailySummarySettingsDescription,
              icon: Icons.summarize_outlined,
              value: settings.dailySummary,
              showDivider: false,
              onChanged: provider.setDailySummary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSection(
    NotificationSettings settings,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) {
    return AppSection(
      title: AppStrings.quietHoursTitle,
      child: AppCard(
        backgroundColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.quietHoursDescription,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            _TimeField(
              label: AppStrings.fromLabel,
              time: startTime,
              onTap: () => _pickTime(true, startTime),
            ),
            const SizedBox(height: AppSpacing.medium),
            _TimeField(
              label: AppStrings.toLabel,
              time: endTime,
              onTap: () => _pickTime(false, endTime),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final formattedTime = localizations.formatTimeOfDay(time);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small + 4,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              formattedTime,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
