import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../courses/models/student_course_view.dart';
import '../../courses/providers/student_courses_provider.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'status_chip.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  final TaskModel task;
  final VoidCallback onTap;

  IconData _getTypeIcon(TaskType type) {
    switch (type) {
      case TaskType.assignment:
        return Icons.menu_book_rounded;
      case TaskType.lecture:
        return Icons.school_rounded;
      case TaskType.study:
        return Icons.groups_rounded;
      case TaskType.exam:
        return Icons.fact_check_outlined;
    }
  }

  String _getTypeLabel(TaskType type) {
    switch (type) {
      case TaskType.assignment:
        return 'واجب';
      case TaskType.lecture:
        return 'محاضرة';
      case TaskType.study:
        return 'دراسة';
      case TaskType.exam:
        return 'اختبار';
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = task.isCompleted;
    final overdue = task.isOverdue();
    final today = task.isToday();

    // Resolve course view dynamically
    final studentCourses = context.watch<StudentCoursesProvider>();
    StudentCourseView? courseView;

    if (task.enrollmentId != null && task.enrollmentId!.isNotEmpty) {
      // Find in currentCourses first
      for (final c in studentCourses.currentCourses) {
        if (c.enrollment.id == task.enrollmentId) {
          courseView = c;
          break;
        }
      }
      // If not in current courses, fallback to catalog/offering lookup
      if (courseView == null) {
        final course = studentCourses.courseById(task.courseId);
        final offering = studentCourses.offeringById(task.offeringId);
        final semester = studentCourses.semesterById(offering?.semesterId);
        if (course != null) {
          courseView = StudentCourseView(
            enrollment: EnrollmentModel(
              id: task.enrollmentId!,
              userId: task.userId,
              offeringId: task.offeringId ?? '',
              courseId: task.courseId ?? '',
              semesterId: offering?.semesterId ?? '',
              status: EnrollmentModel.statusActive,
              assignedBy: '',
            ),
            course: course,
            offering: offering,
            semester: semester,
          );
        }
      }
    }

    String dueText = 'بدون موعد تسليم';
    if (task.dueAt != null) {
      final formatter = DateFormat('yyyy/MM/dd · hh:mm a', 'ar');
      dueText = formatter.format(task.dueAt!);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        onTap: onTap,
        borderColor: completed
            ? AppColors.activeStatus.withValues(alpha: 0.3)
            : (overdue ? AppColors.danger.withValues(alpha: 0.3) : AppColors.borderLight),
        backgroundColor: completed ? AppColors.surface.withValues(alpha: 0.7) : AppColors.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Checkbox for completion toggle
            GestureDetector(
              onTap: () {
                final provider = context.read<TaskProvider>();
                if (completed) {
                  provider.reopenTask(task.id);
                } else {
                  provider.completeTask(task.id);
                }
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: completed ? AppColors.activeStatus : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: completed ? AppColors.activeStatus : AppColors.border,
                    width: 2.0,
                  ),
                ),
                child: completed
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: completed ? AppColors.textMuted : AppColors.textPrimary,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        decoration: completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.small),
                  // Course Link Badge
                  if (courseView != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTypeIcon(task.type),
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${courseView.courseCode} - ${courseView.title} · ${_getTypeLabel(task.type)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTypeIcon(task.type),
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTypeLabel(task.type),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.medium),
                  // Footer: Time and Chips
                  Row(
                    children: [
                      Icon(
                        overdue
                            ? Icons.report_problem_rounded
                            : (today ? Icons.access_time_rounded : Icons.calendar_today_rounded),
                        size: 16,
                        color: overdue
                            ? AppColors.danger
                            : (today ? AppColors.warning : AppColors.textMuted),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dueText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: overdue
                                ? AppColors.danger
                                : (today ? AppColors.warning : AppColors.textMuted),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip.priority(task.priority),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
