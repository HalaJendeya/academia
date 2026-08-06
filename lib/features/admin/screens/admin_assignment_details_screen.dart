import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

class AdminAssignmentDetailsScreen extends StatelessWidget {
  const AdminAssignmentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assignment =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (assignment == null) {
      return const AdminAccessGuard(
        child: Scaffold(
          body: Center(child: Text(AppStrings.assignmentMockTitle)),
        ),
      );
    }

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.assignmentDetailsTitle),
          leading: const AdminBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warn banner
              AppCard(
                backgroundColor: AppColors.warning.withValues(alpha: 0.05),
                borderColor: AppColors.warning.withValues(alpha: 0.2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warningDark,
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Text(
                        AppStrings.assignmentFeatureNotConnected,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.warningDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment['title'] ?? '',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      '${AppStrings.coursePrefix} ${assignment['courseName'] ?? ''}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.deadlinePrefix} ${assignment['dueDate'] ?? ''}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      AppStrings.assignmentInstructionsLabel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assignment['description'] ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),

              // Mock attachment section
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.filesTab,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    const Text(
                      AppStrings.attachmentsUnavailable,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
