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

class AdminCourseFilesScreen extends StatelessWidget {
  const AdminCourseFilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep it empty since we do not fabricate mock records
    final List<dynamic> courseFiles = [];

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.filesManagementTitle),
          leading: const AdminBackButton(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.adminUploadFile);
          },
          label: const Text(AppStrings.uploadNewFileAction),
          icon: const Icon(Icons.upload_rounded),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: courseFiles.isEmpty
            ? AppEmptyState(
                title: AppStrings.noFilesUploadedTitle,
                description: AppStrings.noFilesUploadedDesc,
                icon: Icons.folder_open_rounded,
                actionLabel: AppStrings.uploadNewFileAction,
                onAction: () {
                  Navigator.of(context).pushNamed(AppRoutes.adminUploadFile);
                },
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.medium),
                itemCount: courseFiles.length,
                itemBuilder: (context, index) {
                  final file = courseFiles[index];
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        file['fileName'] ?? '',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${AppStrings.coursePrefix} ${file['courseName'] ?? ''}',
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${AppStrings.fileSizePrefix} ${file['fileSize'] ?? ''} | ${AppStrings.uploadedAtPrefix} ${file['uploadedAt'] ?? ''}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.danger,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
