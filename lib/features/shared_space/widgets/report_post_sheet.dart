// lib/features/shared_space/widgets/report_post_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';

class _ReportReason {
  const _ReportReason(this.value, this.label);
  final String value;
  final String label;
}

const List<_ReportReason> _reportReasons = [
  _ReportReason('inappropriate_content', 'محتوى غير مناسب'),
  _ReportReason('misleading_information', 'معلومات مضللة'),
  _ReportReason('abuse', 'إساءة'),
  _ReportReason('unrelated', 'غير متعلق بالمساق'),
];

/// نافذة الإبلاغ عن منشور، مطابقة لتصميم الفيجما.
///
/// تستقبل [PostModel] كاملًا بدل postId منفصل — postId وcourseId كلاهما
/// موجودان أصلًا على أي منشور معروض، فلا داعي لتمرير معرّفين منفصلين قد
/// يُنسى أحدهما أو يُخطأ ترتيبهما من مكان الاستدعاء.
class ReportPostSheet extends StatefulWidget {
  const ReportPostSheet({super.key, required this.post});

  final PostModel post;

  static Future<void> show(BuildContext context, {required PostModel post}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ReportPostSheet(post: post),
    );
  }

  @override
  State<ReportPostSheet> createState() => _ReportPostSheetState();
}

class _ReportPostSheetState extends State<ReportPostSheet> {
  String? _selectedReason = _reportReasons.first.value;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<PostProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await provider.reportPost(
      postId: widget.post.id,
      courseId: widget.post.courseId,
      reason: _selectedReason!,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    navigator.pop();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'تم إرسال البلاغ بنجاح' : 'تعذر إرسال البلاغ، حاول مرة أخرى',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: _selectedReason,
      onChanged: (value) => setState(() => _selectedReason = value),
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.small),
              Text(
                'يساعدنا بلاغك في الحفاظ على مجتمع أكاديميا آمنًا ومفيدًا. '
                    'يرجى تحديد سبب البلاغ:',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.medium),
              ..._reportReasons.map(_buildReasonTile),
              const SizedBox(height: AppSpacing.small),
              Text(
                'ملاحظات إضافية (اختياري)',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.extraSmall),
              TextField(
                controller: _notesController,
                textAlign: TextAlign.right,
                maxLines: 3,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'اكتب تفاصيل إضافية هنا...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
                )
                    : const Icon(Icons.send_rounded, size: 18, color: AppColors.textOnPrimary),
                label: Text(
                  'إرسال البلاغ',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            'الإبلاغ عن المنشور',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonTile(_ReportReason reason) {
    final isSelected = _selectedReason == reason.value;
    return InkWell(
      onTap: () => setState(() => _selectedReason = reason.value),
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.small),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small, vertical: AppSpacing.small),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: reason.value,
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Text(
                reason.label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}