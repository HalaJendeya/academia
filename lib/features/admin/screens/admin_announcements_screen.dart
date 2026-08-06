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

class AdminAnnouncementsScreen extends StatelessWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep it empty since we do not fabricate mock records
    final List<dynamic> announcements = [];

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.announcementsManagementTitle),
          leading: const AdminBackButton(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.adminAddAnnouncement);
          },
          label: const Text(AppStrings.createNewAnnouncementAction),
          icon: const Icon(Icons.add_rounded),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            children: [
              Expanded(
                child: announcements.isEmpty
                    ? AppEmptyState(
                        title: AppStrings.noAnnouncementsPublishedTitle,
                        description: AppStrings.noAnnouncementsPublishedDesc,
                        icon: Icons.campaign_rounded,
                        actionLabel: AppStrings.createNewAnnouncementAction,
                        onAction: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.adminAddAnnouncement);
                        },
                      )
                    : ListView.builder(
                        itemCount: announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = announcements[index];
                          final target = announcement['target'] == 'all'
                              ? AppStrings.announcementTargetAllValue
                              : '${AppStrings.courseLabelPrefix}${announcement['courseName'] ?? ''}';

                          return AppCard(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.medium,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        announcement['title'] ?? '',
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        target,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.medium),
                                Text(
                                  announcement['body'] ?? '',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Divider(color: AppColors.divider),
                                const SizedBox(height: 4),
                                Text(
                                  '${AppStrings.publishedAtPrefix}${announcement['date'] ?? ''}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
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
