import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../profile/models/support_request.dart';

/// ما اختاره المشرف في حوار التفاصيل.
enum SupportRequestAction { markResolved, reopen }

/// تفاصيل طلب دعم واحد مع إجراء دورة الحياة.
///
/// حوار لا شاشة، كما في حوارَي تسجيل النتيجة وتعديل بيانات الملف: الطلب
/// بيانات معروضة وإجراء واحد، ولا يستحق مسارًا خاصًا به.
///
/// عرضٌ فقط: لا رد ولا مراسلة. ما كتبه الطالب يُقرأ ولا يُعدَّل.
class SupportRequestDetailsDialog extends StatelessWidget {
  const SupportRequestDetailsDialog({super.key, required this.request});

  final SupportRequest request;

  static Future<SupportRequestAction?> show(
    BuildContext context,
    SupportRequest request,
  ) {
    return showDialog<SupportRequestAction>(
      context: context,
      builder: (_) => SupportRequestDetailsDialog(request: request),
    );
  }

  /// تنسيق التاريخ، أو بديل واضح للمستندات التي لا تحمل createdAt.
  static String formatDate(DateTime? value) {
    if (value == null) return AppStrings.supportRequestUnknownValue;
    return DateFormat('yyyy/MM/dd · hh:mm a', 'ar').format(value);
  }

  /// أي حقل نصي ناقص يُعرض كـ«غير محدد» بدل فراغ يوهم بأن البيانات معطوبة.
  static String orUnknown(String value) =>
      value.trim().isEmpty ? AppStrings.supportRequestUnknownValue : value;

  @override
  Widget build(BuildContext context) {
    final isOpen = request.isOpen;

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(
            child: Text(
              AppStrings.supportRequestDetailsTitle,
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          AppStatusBadge(
            label: isOpen
                ? AppStrings.supportStatusOpen
                : AppStrings.supportStatusResolved,
            backgroundColor: (isOpen ? AppColors.warning : AppColors.activeStatus)
                .withValues(alpha: 0.12),
            foregroundColor: isOpen
                ? AppColors.warningDark
                : AppColors.activeStatus,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                AppStrings.supportRequesterLabel,
                orUnknown(request.fullName),
              ),
              _field(
                AppStrings.studentEmailLabel,
                orUnknown(request.email),
              ),
              _field(
                AppStrings.supportRequestDateLabel,
                formatDate(request.createdAt),
              ),
              const Divider(color: AppColors.divider),
              _field(
                AppStrings.supportRequestSubjectLabel,
                orUnknown(request.subject),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                AppStrings.supportRequestMessageLabel,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 4),
              Text(
                orUnknown(request.message),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(
              isOpen
                  ? SupportRequestAction.markResolved
                  : SupportRequestAction.reopen,
            ),
            child: Text(
              isOpen
                  ? AppStrings.supportMarkResolvedAction
                  : AppStrings.supportReopenAction,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.closeAction),
        ),
      ],
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
