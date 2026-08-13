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
  });

  final TaskQuickFilter selected;
  final ValueChanged<TaskQuickFilter> onChanged;
  final int overdueCount;
  final VoidCallback onOpenAdvancedFilter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
        child: Row(
          children: [
            _FilterPill(
              label: 'الكل',
              selected: selected == TaskQuickFilter.all,
              onTap: () => onChanged(TaskQuickFilter.all),
            ),
            _FilterPill(
              label: 'اليوم',
              selected: selected == TaskQuickFilter.today,
              onTap: () => onChanged(TaskQuickFilter.today),
            ),
            _FilterPill(
              label: 'متأخرة',
              selected: selected == TaskQuickFilter.overdue,
              count: overdueCount,
              onTap: () => onChanged(TaskQuickFilter.overdue),
            ),
            _FilterPill(
              label: 'قادمة',
              selected: selected == TaskQuickFilter.upcoming,
              onTap: () => onChanged(TaskQuickFilter.upcoming),
            ),
            _FilterPill(
              label: 'مكتملة',
              selected: selected == TaskQuickFilter.completed,
              onTap: () => onChanged(TaskQuickFilter.completed),
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
