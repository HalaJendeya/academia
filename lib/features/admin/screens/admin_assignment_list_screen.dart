import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

class AdminAssignmentListScreen extends StatelessWidget {
  const AdminAssignmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep it empty/proper empty state since we are not using fabricated mock records
    final List<dynamic> assignments = [];

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.assignmentsManagementTitle),
          leading: const AdminBackButton(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.adminAddAssignment);
          },
          label: const Text(AppStrings.addNewAssignmentAction),
          icon: const Icon(Icons.add_rounded),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: assignments.isEmpty
            ? AppEmptyState(
                title: AppStrings.noAssignmentsAddedTitle,
                description: AppStrings.noAssignmentsAddedDesc,
                icon: Icons.assignment_outlined,
                actionLabel: AppStrings.addNewAssignmentAction,
                onAction: () {
                  Navigator.of(context).pushNamed(AppRoutes.adminAddAssignment);
                },
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.medium),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.adminAssignmentDetails,
                        arguments: assignment,
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment['title'] ?? '',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
