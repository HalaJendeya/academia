// lib/features/files/widgets/student_all_file_card.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/course_file_model.dart';
import 'student_file_type_icon.dart';

/// بطاقة ملف في شاشة "كل الملفات".
///
/// التصميم كما هو من عمل الواجهة؛ ما تغيّر هو المصدر: [CourseFileModel]
/// الحقيقي بدل نموذج وهمي.
///
/// [subjectLabel] يُمرَّر من الشاشة: اسم المساق يخص الطرح لا الملف.
///
/// زرّا التنزيل والحذف أُزيلا: التنزيل غير المتصل مؤجَّل، والحذف ممنوع
/// للطالب في قواعد الأمان أصلًا — زرّ لا يمكن أن ينجح أسوأ من غيابه.
class AllFileCard extends StatelessWidget {
  const AllFileCard({
    super.key,
    required this.file,
    required this.subjectLabel,
    this.onTap,
    this.now,
  });

  final CourseFileModel file;
  final String subjectLabel;
  final VoidCallback? onTap;

  /// اللحظة المرجعية لشارة «جديد». تُحقن في الاختبارات.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FileTypeIcon(type: file.typeGroup),
          const SizedBox(width: AppSpacing.medium),
          Expanded(child: _buildInfo()),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    final subject = subjectLabel.trim().isEmpty
        ? AppStrings.notProvidedValue
        : subjectLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                file.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
                softWrap: true,
              ),
            ),
            if (file.isRecent(now: now)) ...[
              const SizedBox(width: 6),
              _buildNewBadge(),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$subject • ${file.readableSize}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        AppStrings.newFileBadgeLabel,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
