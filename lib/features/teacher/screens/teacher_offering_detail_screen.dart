import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../admin/screens/admin_course_files_screen.dart';
import '../models/teacher_offering_view.dart';
import '../providers/teacher_offerings_provider.dart';
import '../widgets/teacher_access_guard.dart';
import '../widgets/teacher_offering_card.dart';

/// تفاصيل طرح مسند إلى المعلّم، ومنه قائمة الطلاب المسجَّلين.
///
/// القائمة للقراءة فقط في هذه المرحلة: تسجيل النتائج يبقى بيد المشرف، وقاعدة
/// تحديث enrollments هي الأضيق في النظام كله ولا تُفتح مقابل حقل عرض.
class TeacherOfferingDetailScreen extends StatefulWidget {
  const TeacherOfferingDetailScreen({super.key});

  @override
  State<TeacherOfferingDetailScreen> createState() =>
      _TeacherOfferingDetailScreenState();
}

class _TeacherOfferingDetailScreenState
    extends State<TeacherOfferingDetailScreen> {
  /// مرجع محفوظ: لا يمكن قراءة المزوّد من context أثناء التفكيك.
  TeacherOfferingsProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<TeacherOfferingsProvider>();
  }

  @override
  void dispose() {
    // القائمة خاصة بهذه الشاشة؛ الاستماع إليها يتوقف بمغادرتها.
    _provider?.stopListeningToRoster();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherOfferingsProvider>();
    final view = provider.selectedOffering;

    return TeacherAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.teacherOfferingDetailTitle),
          centerTitle: true,
          actions: [
            if (view != null)
              IconButton(
                icon: const Icon(Icons.folder_open_rounded),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.teacherOfferingFiles,
                    arguments: OfferingFilesArgs(
                      offering: view.offering,
                      courseTitle: view.displayTitle,
                    ),
                  );
                },
              ),
          ],
        ),
        body: view == null
            /*
             * الطرح لم يعد ضمن المسندة إلى هذا المعلّم — سُحب الإسناد بينما
             * الشاشة مفتوحة. تُعرض حالة صريحة بدل بيانات لم تعد له.
             */
            ? const AppEmptyState(
                title: AppStrings.teacherCoursesDeferredTitle,
                description: AppStrings.teacherCoursesDeferredDesc,
                icon: Icons.menu_book_outlined,
              )
            : Column(
                children: [
                  _buildHeader(view, provider),
                  Expanded(child: _buildRoster(provider)),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(
    TeacherOfferingView view,
    TeacherOfferingsProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              view.displayTitle,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (view.semesterName.isNotEmpty)
                  AppStatusBadge(
                    label: view.semesterName,
                    backgroundColor: AppColors.surfaceSecondary,
                    foregroundColor: AppColors.textSecondary,
                    icon: Icons.event_note_rounded,
                  ),
                AppStatusBadge(
                  label: '${AppStrings.offeringSectionLabel} ${view.section}',
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.textSecondary,
                ),
                if (view.creditHours != null)
                  AppStatusBadge(
                    label: '${view.creditHours} ${AppStrings.creditHoursShort}',
                    backgroundColor: AppColors.surfaceSecondary,
                    foregroundColor: AppColors.textSecondary,
                  ),
                AppStatusBadge(
                  label: TeacherOfferingCard.statusLabel(view.isActive),
                  backgroundColor: TeacherOfferingCard.statusColor(
                    view.isActive,
                  ).withValues(alpha: 0.08),
                  foregroundColor: TeacherOfferingCard.statusColor(
                    view.isActive,
                  ),
                ),
                /*
                 * العدد لا يظهر قبل اكتمال قراءة القائمة: صفر أثناء التحميل
                 * يقول "لا طلاب"، وهو ادّعاء لا نملكه بعد.
                 */
                if (!provider.isLoadingRoster &&
                    provider.rosterErrorMessage == null)
                  AppStatusBadge(
                    label:
                        '${AppStrings.offeringRosterCountLabel}: '
                        '${provider.roster.length}',
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    foregroundColor: AppColors.primary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoster(TeacherOfferingsProvider provider) {
    if (provider.isLoadingRoster && provider.roster.isEmpty) {
      return const AppLoadingState();
    }

    if (provider.rosterErrorMessage != null) {
      return AppErrorState(message: provider.rosterErrorMessage!);
    }

    if (provider.roster.isEmpty) {
      return const AppEmptyState(
        title: AppStrings.teacherRosterEmptyTitle,
        description: AppStrings.teacherRosterEmptyDesc,
        icon: Icons.groups_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.huge,
      ),
      itemCount: provider.roster.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.small),
            child: Text(
              AppStrings.teacherRosterTitle,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
              textAlign: TextAlign.right,
            ),
          );
        }
        return _buildRosterCard(provider.roster[index - 1]);
      },
    );
  }

  Widget _buildRosterCard(TeacherRosterEntry entry) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  // اسم غير متاح يُقال صراحةً، ولا يُستبدل بمعرّف خام.
                  entry.fullName ?? AppStrings.teacherUnknownStudentName,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: entry.fullName == null
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: '${AppStrings.attemptLabel} ${entry.attemptNumber}',
                backgroundColor: entry.isRetake
                    ? AppColors.warning.withValues(alpha: 0.12)
                    : AppColors.surfaceSecondary,
                foregroundColor: entry.isRetake
                    ? AppColors.warningDark
                    : AppColors.textSecondary,
              ),
            ],
          ),
          if (entry.studentId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.studentId,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }
}
