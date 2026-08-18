import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';

/// لوحة المعلّم.
///
/// المرحلة 8A تُنشئ الهيكل فقط. لا أعداد مساقات ولا طلاب ولا واجبات: تلك
/// بيانات لا مصدر لها بعد، وعرض صفر مكانها ادّعاء لا نملكه. الهوية وحدها
/// حقيقية، ومصدرها AuthProvider.
class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().currentUserProfile;
    final name = profile?.fullName ?? AppStrings.teacherRoleLabel;

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
            AppCard(
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
            ),
            const SizedBox(height: AppSpacing.large),
            const AppEmptyState(
              title: AppStrings.teacherDashboardDeferredTitle,
              description: AppStrings.teacherDashboardDeferredDesc,
              icon: Icons.insights_outlined,
            ),
          ],
        ),
      ),
    );
  }
}
