import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// أقسام شاشة مساقات الطالب.
enum StudentCoursesTab { program, availableNow, current, history }

/// شرائح التبويب بأسلوب فريق الواجهة نفسه (حبّات pill)، موسَّعة من قسمين
/// إلى أربعة ومجعولة قابلة للتمرير أفقيًا حتى لا تتزاحم على شاشة ضيقة.
class CourseStatusTabs extends StatelessWidget {
  const CourseStatusTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.labels,
  });

  final StudentCoursesTab selected;
  final ValueChanged<StudentCoursesTab> onChanged;
  final Map<StudentCoursesTab, String> labels;

  @override
  Widget build(BuildContext context) {
    // بلا reverse: في اتجاه RTL يبدأ التمرير الأفقي من اليمين أصلًا، وإضافة
    // reverse تقلبه فيبدأ العرض من آخر تبويب بدل أوّله.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in StudentCoursesTab.values) ...[
            _StatusChip(
              label: labels[tab] ?? '',
              isSelected: selected == tab,
              onTap: () => onChanged(tab),
            ),
            if (tab != StudentCoursesTab.values.last)
              const SizedBox(width: AppSpacing.small),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
