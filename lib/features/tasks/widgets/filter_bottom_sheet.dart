import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../models/task_model.dart';
import '../../courses/models/student_course_view.dart';

class TaskFilter {
  final TaskStatus? status;
  final TaskPriority? priority;
  final String? enrollmentId;

  const TaskFilter({
    this.status,
    this.priority,
    this.enrollmentId,
  });

  bool get isEmpty => status == null && priority == null && enrollmentId == null;
}

Future<TaskFilter?> showTaskFilterBottomSheet(
  BuildContext context, {
  required TaskFilter currentFilter,
  required List<StudentCourseView> currentCourses,
}) {
  return showModalBottomSheet<TaskFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppRadius.card),
        topRight: Radius.circular(AppRadius.card),
      ),
    ),
    builder: (context) {
      return _FilterBottomSheetContent(
        initialFilter: currentFilter,
        currentCourses: currentCourses,
      );
    },
  );
}

class _FilterBottomSheetContent extends StatefulWidget {
  const _FilterBottomSheetContent({
    required this.initialFilter,
    required this.currentCourses,
  });

  final TaskFilter initialFilter;
  final List<StudentCourseView> currentCourses;

  @override
  State<_FilterBottomSheetContent> createState() => _FilterBottomSheetContentState();
}

class _FilterBottomSheetContentState extends State<_FilterBottomSheetContent> {
  TaskStatus? selectedStatus;
  TaskPriority? selectedPriority;
  String? selectedEnrollmentId;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialFilter.status;
    selectedPriority = widget.initialFilter.priority;
    selectedEnrollmentId = widget.initialFilter.enrollmentId;
  }

  void _reset() {
    setState(() {
      selectedStatus = null;
      selectedPriority = null;
      selectedEnrollmentId = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      TaskFilter(
        status: selectedStatus,
        priority: selectedPriority,
        enrollmentId: selectedEnrollmentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.large,
          left: AppSpacing.medium,
          right: AppSpacing.medium,
          top: AppSpacing.medium,
        ),
        child: MainList(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'تصفية المهام',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _reset,
                  child: const Text(
                    'إعادة ضبط',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.small),
            const _SectionLabel('حالة المهمة'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskStatus.values.map((status) {
                final active = selectedStatus == status;
                final label = status == TaskStatus.completed ? 'مكتملة' : 'قيد الانتظار';
                return _FilterPill(
                  label: label,
                  active: active,
                  onTap: () => setState(() => selectedStatus = active ? null : status),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.medium),
            const _SectionLabel('الأولوية'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskPriority.values.map((priority) {
                final active = selectedPriority == priority;
                String label;
                switch (priority) {
                  case TaskPriority.high:
                    label = 'عالية';
                    break;
                  case TaskPriority.medium:
                    label = 'متوسطة';
                    break;
                  case TaskPriority.low:
                    label = 'منخفضة';
                    break;
                }
                return _FilterPill(
                  label: label,
                  active: active,
                  onTap: () => setState(() => selectedPriority = active ? null : priority),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.medium),
            const _SectionLabel('المساق المرتبط'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedEnrollmentId,
              isExpanded: true,
              hint: const Text('اختر مساقاً لتصفية المهام'),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('الكل (بدون تصفية حسب المساق)'),
                ),
                ...widget.currentCourses.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.enrollment.id,
                    child: Text('${c.courseCode} - ${c.title}'),
                  );
                }),
              ],
              onChanged: (value) => setState(() => selectedEnrollmentId = value),
            ),
            const SizedBox(height: AppSpacing.large),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                elevation: 0,
              ),
              onPressed: _apply,
              child: const Text(
                'تطبيق التصفية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.12) : Colors.white,
          border: Border.all(color: active ? AppColors.primary : AppColors.borderLight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// Simple wrapper to allow scroll in bottom sheet if needed
class MainList extends StatelessWidget {
  const MainList({
    super.key,
    required this.children,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<Widget> children;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }
}
