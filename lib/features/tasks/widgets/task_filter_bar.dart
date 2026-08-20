import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

enum TaskQuickFilter { all, today, overdue, upcoming, completed }

class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.overdueCount,
    required this.onOpenAdvancedFilter,
    this.visibleFilters = TaskQuickFilter.values,
  });

  final TaskQuickFilter selected;
  final ValueChanged<TaskQuickFilter> onChanged;
  final int overdueCount;
  final VoidCallback onOpenAdvancedFilter;

  /// أي مرشِّحات سريعة تُعرض.
  ///
  /// الافتراضي كل القيم، فسلوك أي مستدعٍ قائم لا يتغيّر. تبويب «مهامي» في
  /// الشاشة الموحَّدة يمرّر مجموعة أضيق: «الكل» و«مكتملة» صارا تبويبين،
  /// وتكرار التسمية نفسها في مستويين يجعل الاختيار غامضًا.
  final List<TaskQuickFilter> visibleFilters;

  static const Map<TaskQuickFilter, String> _labels = {
    TaskQuickFilter.all: 'الكل',
    TaskQuickFilter.today: 'اليوم',
    TaskQuickFilter.overdue: 'متأخرة',
    TaskQuickFilter.upcoming: 'قادمة',
    TaskQuickFilter.completed: 'مكتملة',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
        child: Row(
          children: [
            for (final filter in visibleFilters)
              _FilterPill(
                label: _labels[filter]!,
                selected: selected == filter,
                count: filter == TaskQuickFilter.overdue ? overdueCount : null,
                onTap: () => onChanged(filter),
              ),
            _FilterPill(
              label: 'فلترة',
              selected: false,
              icon: Icons.tune_rounded,
              onTap: onOpenAdvancedFilter,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final hasBadge = count != null && count! > 0;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderLight,
              width: 1.0,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              if (hasBadge) ...[
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
