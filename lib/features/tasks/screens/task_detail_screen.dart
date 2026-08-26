import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:academia/core/theme/app_colors.dart';
import 'package:academia/core/theme/app_spacing.dart';
import 'package:academia/core/theme/app_radius.dart';
import 'package:academia/core/widgets/app_top_bar.dart';
import 'package:academia/core/widgets/empty_state.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';
import 'package:academia/features/tasks/widgets/delete_task_dialog.dart';
import 'package:academia/features/tasks/widgets/status_chip.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

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
    final taskId = ModalRoute.of(context)?.settings.arguments as String?;

    if (taskId == null || taskId.isEmpty) {
      return Scaffold(
        appBar: const AcademiaSubAppBar(title: 'تفاصيل المهمة'),
        body: AppEmptyState(
          title: 'المهمة غير موجودة',
          description: 'تعذر العثور على معرّف المهمة المطلوب.',
          icon: Icons.error_outline_rounded,
          actionLabel: 'العودة للمهام',
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    final taskProvider = context.watch<TaskProvider>();
    final matchedTasks = taskProvider.tasks.where((t) => t.id == taskId);

    if (matchedTasks.isEmpty) {
      return Scaffold(
        appBar: const AcademiaSubAppBar(title: 'تفاصيل المهمة'),
        body: AppEmptyState(
          title: 'المهمة غير موجودة',
          description: 'قد تكون هذه المهمة قد حُذفت بالفعل.',
          icon: Icons.assignment_late_outlined,
          actionLabel: 'العودة للمهام',
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    final task = matchedTasks.first;

    final completed = task.isCompleted;

    // Resolve course view dynamically
    final studentCourses = context.watch<StudentCoursesProvider>();
    StudentCourseView? courseView;

    if (task.enrollmentId != null && task.enrollmentId!.isNotEmpty) {
      for (final c in studentCourses.currentCourses) {
        if (c.enrollment.id == task.enrollmentId) {
          courseView = c;
          break;
        }
      }
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AcademiaSubAppBar(title: 'تفاصيل المهمة'),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Task Main Details Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        StatusChip.priority(task.priority),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Row(
                      children: [
                        StatusChip.status(
                          task.status,
                          isOverdue: task.isOverdue(),
                          isToday: task.isToday(),
                          isUpcoming: task.isUpcoming(),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getTypeIcon(task.type), size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                _getTypeLabel(task.type),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Course Details Box if linked
              if (courseView != null) ...[
                const Text(
                  'المساق المرتبط',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${courseView.courseCode} - ${courseView.title}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (courseView.instructorName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'المحاضر: ${courseView.instructorName}',
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                      if (courseView.semesterName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'الفصل الدراسي: ${courseView.semesterName}',
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
              ],

              // Due Date Box
              const Text(
                'موعد التسليم',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      dueText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Description Box
              const Text(
                'الوصف والتفاصيل',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  task.description.isNotEmpty ? task.description : 'لا يوجد وصف مضاف لهذه المهمة.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: task.description.isNotEmpty ? AppColors.textPrimary : AppColors.textDisabled,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.large),

              // Action Buttons
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: completed ? AppColors.warning : AppColors.activeStatus,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  elevation: 0,
                ),
                icon: Icon(completed ? Icons.undo_rounded : Icons.check_rounded),
                label: Text(
                  completed ? 'إعادة فتح المهمة' : 'تم إنجاز المهمة',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (completed) {
                    taskProvider.reopenTask(task.id);
                  } else {
                    taskProvider.completeTask(task.id);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.small),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'تعديل المهمة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/tasks/create-edit',
                    arguments: task,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.small),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text(
                  'حذف المهمة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final confirm = await showDeleteTaskDialog(context);
                  if (confirm == true) {
                    await taskProvider.deleteTask(task.id);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
