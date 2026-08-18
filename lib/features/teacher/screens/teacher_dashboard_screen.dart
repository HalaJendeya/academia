import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/teacher_offerings_provider.dart';
import '../widgets/teacher_offering_card.dart';

/// لوحة المعلّم.
///
/// كل رقم هنا مقروء من Firestore: عدد الطروحات النشطة هو طول القائمة
/// المسندة فعلًا. لا عدد طلاب إجمالي — معرفته تتطلب قراءة قائمة كل طرح على
/// حدة، وهو ما لا يستحق مستمعًا لكل طرح مقابل رقم واحد؛ العدد الحقيقي يظهر
/// داخل كل طرح.
class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().currentUserProfile;
    final provider = context.watch<TeacherOfferingsProvider>();
    final name = profile?.fullName ?? AppStrings.teacherRoleLabel;

    final activeOfferings = provider.activeOfferings;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.teacherDashboardTitle),
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
            _buildIdentityCard(name),
            const SizedBox(height: AppSpacing.large),
            _buildActiveCountCard(provider, activeOfferings.length),
            const SizedBox(height: AppSpacing.large),
            if (provider.isLoading && provider.offerings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.large),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (activeOfferings.isEmpty)
              const AppEmptyState(
                title: AppStrings.teacherDashboardDeferredTitle,
                description: AppStrings.teacherDashboardDeferredDesc,
                icon: Icons.insights_outlined,
              )
            else ...[
              Text(
                AppStrings.teacherMyOfferingsTitle,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.small),
              ...activeOfferings.map(
                (view) => TeacherOfferingCard(
                  view: view,
                  onTap: () {
                    context
                        .read<TeacherOfferingsProvider>()
                        .listenToOfferingRoster(view.offeringId);
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.teacherOfferingDetail);
                  },
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard(String name) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.co_present_rounded,
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
                  '${AppStrings.welcomeTeacherPrefix}$name',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const AppStatusBadge(
                  label: AppStrings.teacherRoleLabel,
                  backgroundColor: AppColors.surfaceSecondary,
                  foregroundColor: AppColors.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCountCard(
    TeacherOfferingsProvider provider,
    int activeCount,
  ) {
    /*
     * يُعرض "—" لا صفر ما دامت القراءة جارية أو فاشلة.
     *
     * صفر رقم يدّعي أن المعلّم بلا طروحات نشطة، بينما الحقيقة أننا لا نعرف
     * بعد. الشرطة تقول ذلك بلا ادّعاء.
     */
    final unknown =
        (provider.isLoading && provider.offerings.isEmpty) ||
        provider.errorMessage != null;

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Text(
              AppStrings.teacherActiveOfferingsCountLabel,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            unknown ? '—' : '$activeCount',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
