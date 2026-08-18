import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../models/course_assignment_model.dart';

/// شارات الواجب المشتركة بين واجهات المعلّم والطالب والمشرف.
///
/// موجودة هنا لا في مجلد دور بعينه: الحالة الزمنية والأولوية معنى واحد في
/// المنتج كله، وتكرارها ثلاث مرات يعني أن تختلف ألوانها ثلاث مرات.
///
/// كل ما تعرضه مشتقّ لحظة البناء من [CourseAssignmentModel]؛ لا شيء منه
/// مخزَّن في Firestore.
class AssignmentPriorityBadge extends StatelessWidget {
  const AssignmentPriorityBadge({super.key, required this.priority});

  final String priority;

  static Color colorFor(String priority) {
    switch (priority) {
      case CourseAssignmentModel.priorityHigh:
        return AppColors.danger;
      case CourseAssignmentModel.priorityLow:
        return AppColors.textSecondary;
      default:
        return AppColors.warningDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(priority);
    return AppStatusBadge(
      label: AppStrings.assignmentPriorityDisplay(priority),
      backgroundColor: color.withValues(alpha: 0.08),
      foregroundColor: color,
      icon: Icons.flag_rounded,
    );
  }
}

/// شارة الحالة الزمنية، أو null إن لم يكن للواجب حالة تستحق الإبراز.
///
/// الترتيب مقصود: المتأخر يسبق «مستحق اليوم»، لأن واجبًا فات موعده صباح
/// اليوم هو متأخر لا مستحق. الواجب البعيد لا شارة له — الشارة الدائمة تفقد
/// معناها.
class AssignmentDueStateBadge extends StatelessWidget {
  const AssignmentDueStateBadge({
    super.key,
    required this.assignment,
    this.relativeTo,
  });

  final CourseAssignmentModel assignment;

  /// لحظة مرجعية للاختبارات؛ الإنتاج يستخدم الوقت الحالي.
  final DateTime? relativeTo;

  static ({String label, Color color})? resolve(
    CourseAssignmentModel assignment, {
    DateTime? relativeTo,
  }) {
    if (assignment.isOverdue(relativeTo: relativeTo)) {
      return (label: AppStrings.assignmentOverdueLabel, color: AppColors.error);
    }
    if (assignment.isDueToday(relativeTo: relativeTo)) {
      return (
        label: AppStrings.assignmentDueTodayLabel,
        color: AppColors.warningDark,
      );
    }
    if (assignment.isDueSoon(relativeTo: relativeTo)) {
      return (
        label: AppStrings.assignmentDueSoonLabel,
        color: AppColors.primary,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = resolve(assignment, relativeTo: relativeTo);
    if (state == null) return const SizedBox.shrink();

    return AppStatusBadge(
      label: state.label,
      backgroundColor: state.color.withValues(alpha: 0.1),
      foregroundColor: state.color,
      icon: Icons.schedule_rounded,
    );
  }
}
