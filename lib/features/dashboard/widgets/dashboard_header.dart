import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// ترويسة اللوحة: من هو الطالب وأين هو أكاديميًا.
///
/// الاسم والمستوى يأتيان من مستند المستخدم، واسم التخصص من مستند التخصص
/// المرتبط بـ majorId لا من النص الحر القديم في users.major.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.fullName,
    this.academicLevel,
    this.majorName,
  });

  final String fullName;

  /// رقم صحيح في قاعدة البيانات؛ النص العربي يُبنى هنا وقت العرض فقط.
  final int? academicLevel;

  /// null عندما لا يكون الطالب مرتبطًا ببرنامج أكاديمي بعد.
  final String? majorName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${AppStrings.dashboardGreeting}، $fullName',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.extraSmall),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.school_rounded,
              size: AppSizes.iconExtraSmall,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            // أسماء التخصصات العربية طويلة؛ Expanded يمنع فيض الصف على
            // الشاشات الضيقة ويسمح بلفّها على سطرين.
            Expanded(
              child: Text(
                _subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String get _subtitle {
    final level = academicLevel;
    final levelText = level != null
        ? AppStrings.academicLevelDisplay(level)
        : null;

    final parts = <String>[
      ?levelText,
      if (majorName != null && majorName!.trim().isNotEmpty) majorName!,
    ];

    if (parts.isEmpty) return AppStrings.noMajorTitle;
    return parts.join(' • ');
  }
}
