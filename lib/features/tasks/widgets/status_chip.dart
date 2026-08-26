import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../models/task_model.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  factory StatusChip.priority(TaskPriority priority) {
    String label;
    Color foreground;
    Color background;

    switch (priority) {
      case TaskPriority.high:
        label = 'عالية';
        foreground = AppColors.danger;
        background = AppColors.danger.withValues(alpha: 0.12);
        break;
      case TaskPriority.medium:
        label = 'متوسطة';
        foreground = AppColors.warning;
        background = AppColors.warning.withValues(alpha: 0.12);
        break;
      case TaskPriority.low:
        label = 'منخفضة';
        foreground = AppColors.textMuted;
        background = AppColors.textMuted.withValues(alpha: 0.12);
        break;
    }

    return StatusChip(
      label: label,
      foreground: foreground,
      background: background,
    );
  }

  factory StatusChip.status(TaskStatus status, {bool isOverdue = false, bool isToday = false, bool isUpcoming = false}) {
    String label;
    Color foreground;
    Color background;
    IconData? icon;

    if (status == TaskStatus.completed) {
      label = 'مكتملة';
      foreground = AppColors.activeStatus;
      background = AppColors.activeStatus.withValues(alpha: 0.12);
      icon = Icons.check_rounded;
    } else if (isOverdue) {
      label = 'متأخرة';
      foreground = AppColors.danger;
      background = AppColors.danger.withValues(alpha: 0.12);
    } else if (isToday) {
      label = 'اليوم';
      foreground = AppColors.warning;
      background = AppColors.warning.withValues(alpha: 0.12);
    } else if (isUpcoming) {
      label = 'قادمة';
      foreground = AppColors.textMuted;
      background = AppColors.textMuted.withValues(alpha: 0.12);
    } else {
      label = 'قيد الانتظار';
      foreground = AppColors.textSecondary;
      background = AppColors.borderLight;
    }

    return StatusChip(
      label: label,
      foreground: foreground,
      background: background,
      icon: icon,
    );
  }

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
