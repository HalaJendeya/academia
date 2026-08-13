import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../enrollments/models/enrollment_model.dart';

/// نتيجة الحوار: ما اختاره المشرف، أو null إذا ألغى.
class RecordResultOutcome {
  const RecordResultOutcome({required this.completionStatus, this.grade});

  final String completionStatus;
  final String? grade;
}

/// حوار تسجيل نتيجة محاولة.
///
/// يحلّ محل "تعليم كمكتمل" الذي كان ينهي المحاولة دون نتيجة، فيترك
/// completionStatus فارغًا ويجعل السجل الدراسي بلا معنى: الطالب يرى مساقًا
/// منتهيًا لا يعرف أنجح فيه أم رسب.
Future<RecordResultOutcome?> showRecordResultDialog({
  required BuildContext context,
  required String courseTitle,
  String? initialCompletionStatus,
  String? initialGrade,
}) {
  return showDialog<RecordResultOutcome>(
    context: context,
    builder: (dialogContext) => _RecordResultDialog(
      courseTitle: courseTitle,
      initialCompletionStatus: initialCompletionStatus,
      initialGrade: initialGrade,
    ),
  );
}

class _RecordResultDialog extends StatefulWidget {
  const _RecordResultDialog({
    required this.courseTitle,
    this.initialCompletionStatus,
    this.initialGrade,
  });

  final String courseTitle;
  final String? initialCompletionStatus;
  final String? initialGrade;

  @override
  State<_RecordResultDialog> createState() => _RecordResultDialogState();
}

class _RecordResultDialogState extends State<_RecordResultDialog> {
  late String? _completionStatus = widget.initialCompletionStatus;
  late final TextEditingController _gradeController = TextEditingController(
    text: widget.initialGrade ?? '',
  );

  bool _showValidation = false;

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        AppStrings.recordResultTitle,
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.right,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.courseTitle, textAlign: TextAlign.right),
            const SizedBox(height: AppSpacing.small),
            Text(
              AppStrings.recordResultDesc,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: AppSpacing.medium),

            Text(
              AppStrings.completionStatusLabel,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: AppSpacing.small),
            // ثلاث نتائج فقط، مطابقة لما تقبله قواعد Firestore.
            RadioGroup<String>(
              groupValue: _completionStatus,
              onChanged: (value) => setState(() => _completionStatus = value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final status
                      in EnrollmentModel.allowedCompletionStatuses)
                    RadioListTile<String>(
                      value: status,
                      title: Text(
                        AppStrings.completionStatusDisplay(status),
                        style: AppTextStyles.bodyMedium,
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),

            if (_showValidation && _completionStatus == null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.small),
                child: Text(
                  AppStrings.completionStatusRequired,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

            const SizedBox(height: AppSpacing.small),
            TextField(
              controller: _gradeController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: AppStrings.gradeOptionalLabel,
                hintText: AppStrings.gradeHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final status = _completionStatus;
              if (status == null) {
                setState(() => _showValidation = true);
                return;
              }
              final grade = _gradeController.text.trim();
              Navigator.of(context).pop(
                RecordResultOutcome(
                  completionStatus: status,
                  grade: grade.isEmpty ? null : grade,
                ),
              );
            },
            child: const Text(AppStrings.confirmAction),
          ),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancelAction),
        ),
      ],
    );
  }
}
