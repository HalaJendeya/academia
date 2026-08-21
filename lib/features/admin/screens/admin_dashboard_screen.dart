import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../courses/providers/course_provider.dart';
import '../../enrollments/providers/enrollment_provider.dart';
import '../../files/providers/course_file_provider.dart';
import '../widgets/admin_quick_action_card.dart';
import '../widgets/admin_stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Function(int)? onTabSelect;

  const AdminDashboardScreen({super.key, this.onTabSelect});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseProvider>().listenToCourses();
      context.read<EnrollmentProvider>().listenToStudents();
      // قراءة واحدة لا استماع: بطاقة إحصاء لا تحتاج تحديثًا لحظيًا.
      context.read<CourseFileProvider>().loadActiveFileCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProfile = authProvider.currentUserProfile;
    final adminName = userProfile?.fullName ?? AppStrings.adminRoleLabel;

    final enrollmentProvider = context.watch<EnrollmentProvider>();
    final studentsCount = enrollmentProvider.students.length;

    final courseProvider = context.watch<CourseProvider>();
    final coursesCount = courseProvider.courses.length;
    final activeCoursesCount = courseProvider.courses
        .where((c) => c.status == 'active')
        .length;
    final archivedCoursesCount = courseProvider.courses
        .where((c) => c.status == 'archived')
        .length;

    /*
     * عدد الملفات النشطة من مزوّد الملفات، لا رقم مكتوب في الشاشة.
     * الشرطة تُعرض ما دام الرقم غير معروف — أثناء القراءة أو عند فشلها —
     * لأن عرض صفر يعني "لا ملفات" وهو ادّعاء لا نملكه.
     */
    final fileProvider = context.watch<CourseFileProvider>();
    final activeFilesCount = fileProvider.activeFileCount;
    final activeFilesValue = activeFilesCount?.toString() ?? '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminDashboardTitle),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.screenVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Header Card
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.welcomeAdminPrefix}$adminName',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const AppStatusBadge(
                          label: AppStrings.adminRoleLabel,
                          backgroundColor: AppColors.surfaceSecondary,
                          foregroundColor: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.large),

            // Statistics Grid (2-column layout)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.medium,
              mainAxisSpacing: AppSpacing.medium,
              mainAxisExtent: 108,
              children: [
                AdminStatCard(
                  title: AppStrings.adminStudentsTitle,
                  value: studentsCount.toString(),
                  icon: Icons.groups_rounded,
                  iconColor: AppColors.secondary,
                  iconBackgroundColor: AppColors.secondary.withValues(
                    alpha: 0.1,
                  ),
                ),
                AdminStatCard(
                  title: AppStrings.adminCoursesTitle,
                  value: coursesCount.toString(),
                  icon: Icons.menu_book_rounded,
                  iconColor: AppColors.primary,
                  iconBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
                ),
                const AdminStatCard(
                  title: AppStrings.assignmentsManagementTitle,
                  value: '0',
                  icon: Icons.assignment_outlined,
                  iconColor: AppColors.accentPurple,
                  iconBackgroundColor: AppColors.accentPurpleLight,
                ),
                AdminStatCard(
                  title: AppStrings.filesManagementTitle,
                  value: activeFilesValue,
                  icon: Icons.folder_open_rounded,
                  iconColor: AppColors.accentTeal,
                  iconBackgroundColor: AppColors.accentTealLight,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),

            // Quick Actions Section
            Text(
              AppStrings.quickActionsLabel,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.medium,
              mainAxisSpacing: AppSpacing.medium,
              mainAxisExtent: 140,
              children: [
                AdminQuickActionCard(
                  title: AppStrings.addCourseQuickAction,
                  icon: Icons.add_card_rounded,
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.adminAddCourse);
                  },
                ),
                AdminQuickActionCard(
                  title: AppStrings.manageStudentsQuickAction,
                  icon: Icons.manage_accounts_rounded,
                  color: AppColors.secondary,
                  onTap: () {
                    widget.onTabSelect?.call(2);
                  },
                ),
                AdminQuickActionCard(
                  title: AppStrings.addAssignmentQuickAction,
                  icon: Icons.note_add_rounded,
                  color: AppColors.accentPurple,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.adminAddAssignment);
                  },
                ),
                /*
                 * الرفع يبدأ من الطرح لا من اللوحة.
                 *
                 * شاشة الرفع مقيَّدة بطرح وتطلب UploadFileArgs، والانتقال
                 * إليها مباشرة من هنا كان يعرض "الطرح غير موجود". اللوحة
                 * لا تعرف أي طرح يقصد المشرف، وتلفيق طرح لتمريره يكذب على
                 * الطبقة التي تشتقّ منه المساق والفصل. لذلك ننتقل إلى
                 * شاشة الطروحات ليختار المشرف الطرح، ومنها إلى ملفاته.
                 */
                AdminQuickActionCard(
                  title: AppStrings.uploadFileQuickAction,
                  icon: Icons.upload_file_rounded,
                  color: AppColors.accentTeal,
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.adminOfferings);
                  },
                ),
                /*
                 * ملاحظة على مؤقتية النص: "بلاغات المنشورات" نص مباشر لا
                 * AppStrings.* — نفس مبدأ الالتزام المتّبع بميزة ساحة
                 * المشاركة كلها: نصوصها لم تُدمَج بعد في app_strings.dart
                 * المركزي، على أن تُنقَل لاحقًا دفعة واحدة مع باقي نصوص
                 * الميزة، لا سطرًا سطرًا بمناسبات متفرقة.
                 */
                AdminQuickActionCard(
                  title: 'بلاغات المنشورات',
                  icon: Icons.flag_rounded,
                  color: AppColors.error,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.adminReportedPosts);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),

            // Statistics breakdown section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.courseStatusSummary,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  /*
                   * كل عمود مرن يأخذ نصف العرض: التسميتان العربيتان
                   * الطويلتان كانتا تفيضان عن الصف على عرض 360 لأن العمودين
                   * كانا بلا عامل مرونة، فيطلبان عرضهما الطبيعي كاملًا.
                   */
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              activeCoursesCount.toString(),
                              style: AppTextStyles.headlineMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.activeStatus,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              AppStrings.activeCoursesLabel,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              archivedCoursesCount.toString(),
                              style: AppTextStyles.headlineMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              AppStrings.archivedCoursesLabel,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.large),

            // Recent Activity Section (Empty state only, no fabricated records)
            Text(
              AppStrings.recentActivitiesLabel,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            AppCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
                child: Column(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 40,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      AppStrings.noRecentActivities,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}