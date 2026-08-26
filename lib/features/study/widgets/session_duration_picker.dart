import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/study_session_model.dart';

/// اختيار مدة الجلسة — صف رقائق أفقي كما في إطار Figma‏ 96:515.
///
/// Wrap لا ListView أفقي: على عرض 360 لا تتسع الخيارات في سطر واحد، والالتفاف
/// أوضح من تمرير أفقي مخفي لا يلاحظه الطالب.
///
/// المدة المخزَّنة في تفضيلات الطالب قد تخرج عن الخيارات الثابتة، فتُعرض
/// كرقاقة إضافية بدل أن تختفي ويبدو كأنه لم يختر شيئًا.
class SessionDurationPicker extends StatelessWidget {
  const SessionDurationPicker({
    super.key,
    required this.selectedMinutes,
    required this.onSelected,
  });

  final int selectedMinutes;
  final ValueChanged<int> onSelected;

  static const List<int> presets = [15, 25, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final options = [...presets];
    if (!options.contains(selectedMinutes) &&
        StudySessionModel.isValidDuration(selectedMinutes)) {
      options.add(selectedMinutes);
      options.sort();
    }

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: [
        for (final minutes in options)
          _DurationChip(
            minutes: minutes,
            selected: minutes == selectedMinutes,
            onTap: () => onSelected(minutes),
          ),
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.small + 2,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            '$minutes ${AppStrings.minutesUnit}',
            style: AppTextStyles.labelMedium.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
