import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_menu_tile.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';
import '../../academics/providers/academic_structure_provider.dart';
import '../../courses/models/course_model.dart';

class AdminCourseDetailsScreen extends StatelessWidget {
  const AdminCourseDetailsScreen({super.key});

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.medium),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = ModalRoute.of(context)?.settings.arguments as CourseModel?;

    if (course == null) {
      return const AdminAccessGuard(
        child: Scaffold(body: Center(child: Text(AppStrings.courseNotFound))),
      );
    }

    final statusColor = course.isActive
        ? AppColors.activeStatus
        : AppColors.textMuted;
    final statusBgColor = statusColor.withValues(alpha: 0.08);

    return AdminAccessGuard(
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(course.title),
            leading: const AdminBackButton(),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Course Summary Card
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              course.title,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppStatusBadge(
                            label: course.isActive
                                ? AppStrings.activeStatus
                                : AppStrings.archivedStatus,
                            backgroundColor: statusBgColor,
                            foregroundColor: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      _buildInfoRow(
                        Icons.code_rounded,
                        AppStrings.courseCodeLabel,
                        course.courseCode,
                      ),
                      /*
                       * المدرّس والفصل الدراسي لم يعودا من بيانات المساق:
                       * كلاهما يخص الطرح، ويُعرضان في شاشة الطروحات.
                       */
                      _buildInfoRow(
                        Icons.account_tree_rounded,
                        AppStrings.courseDepartmentLabel,
                        context
                            .watch<AcademicStructureProvider>()
                            .departmentNameFor(course.departmentId),
                      ),
                      _buildInfoRow(
                        Icons.hourglass_bottom_rounded,
                        AppStrings.creditHoursLabel,
                        '${course.creditHours} ${AppStrings.creditHoursSuffix}',
                      ),
                      if (course.description.isNotEmpty) ...[
                        const Divider(height: 20, color: AppColors.divider),
                        Text(
                          course.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              /*
               * إدارة الطروحات وصلت في المرحلة 7E، فالبلاطة مفعَّلة الآن.
               *
               * تفتح شاشة الطروحات القائمة بلا وسيطات: تلك الشاشة مقيَّدة
               * بفصل دراسي لا بمساق، ولا تقبل تصفية حسب المساق. تركها بلا
               * وسيطات يجعلها تبدأ من الفصل الحالي، وهو الفصل الذي يعمل
               * عليه المشرف.
               */
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: AppMenuTile(
                    icon: Icons.event_repeat_rounded,
                    title: AppStrings.courseOfferingsTileTitle,
                    subtitle: AppStrings.courseOfferingsTileDesc,
                    showDivider: false,
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.adminOfferings);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Tab Selector
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: AppStrings.enrolledStudentsTab),
                  Tab(text: AppStrings.assignmentsTab),
                  Tab(text: AppStrings.filesTab),
                  Tab(text: AppStrings.announcementsTab),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTabEmptyState(
                      Icons.groups_outlined,
                      AppStrings.enrolledStudentsNotConnectedTitle,
                      AppStrings.enrolledStudentsNotConnectedDesc,
                    ),
                    _buildTabEmptyState(
                      Icons.assignment_outlined,
                      AppStrings.noAssignmentsTitle,
                      AppStrings.noAssignmentsDesc,
                    ),
                    _buildTabEmptyState(
                      Icons.folder_open_outlined,
                      AppStrings.noFilesTitle,
                      AppStrings.noFilesDesc,
                    ),
                    _buildTabEmptyState(
                      Icons.campaign_outlined,
                      AppStrings.noAnnouncementsTitle,
                      AppStrings.noAnnouncementsDesc,
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
