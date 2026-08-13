import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

class AdminReportedPostsScreen extends StatelessWidget {
  const AdminReportedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep it empty since we do not fabricate mock records
    final List<dynamic> reports = [];

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.reportedPostsTitle),
          leading: const AdminBackButton(),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            children: [
              Expanded(
                child: reports.isEmpty
                    ? const AppEmptyState(
                        title: AppStrings.noReportsTitle,
                        description: AppStrings.noReportsDesc,
                        icon: Icons.check_circle_outline_rounded,
                      )
                    : ListView.builder(
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.medium,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.medium),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        report['reporterName'] ?? '',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        report['reason'] ?? '',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  Text(report['postContent'] ?? ''),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
