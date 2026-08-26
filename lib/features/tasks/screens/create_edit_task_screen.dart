import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:academia/core/theme/app_colors.dart';
import 'package:academia/core/theme/app_spacing.dart';
import 'package:academia/core/theme/app_radius.dart';
import 'package:academia/core/widgets/app_top_bar.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';
import 'package:academia/features/tasks/services/task_service.dart';

class CreateEditTaskScreen extends StatefulWidget {
  const CreateEditTaskScreen({super.key});

  @override
  State<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends State<CreateEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  TaskModel? existingTask;
  bool isEditing = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  String? selectedEnrollmentId;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TaskPriority selectedPriority = TaskPriority.medium;
  TaskType selectedType = TaskType.study;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      existingTask = ModalRoute.of(context)?.settings.arguments as TaskModel?;
      isEditing = existingTask != null;

      if (isEditing && existingTask != null) {
        _titleController.text = existingTask!.title;
        _descriptionController.text = existingTask!.description;
        selectedEnrollmentId = existingTask!.enrollmentId;
        selectedPriority = existingTask!.priority;
        selectedType = existingTask!.type;

        if (existingTask!.dueAt != null) {
          selectedDate = existingTask!.dueAt;
          selectedTime = TimeOfDay.fromDateTime(existingTask!.dueAt!);
        }
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 23, minute: 59),
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _save(List<StudentCourseView> currentCourses) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    DateTime? dueAt;
    if (selectedDate != null) {
      dueAt = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime?.hour ?? 23,
        selectedTime?.minute ?? 59,
      );
    }

    try {
      final provider = context.read<TaskProvider>();
      if (isEditing && existingTask != null) {
        await provider.updateTask(
          taskId: existingTask!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          dueAt: dueAt,
          priority: selectedPriority,
          type: selectedType,
          enrollmentId: selectedEnrollmentId,
          currentCourses: currentCourses,
          status: existingTask!.status,
        );
      } else {
        await provider.createTask(
          title: _titleController.text,
          description: _descriptionController.text,
          dueAt: dueAt,
          priority: selectedPriority,
          type: selectedType,
          enrollmentId: selectedEnrollmentId,
          currentCourses: currentCourses,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on TaskException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء حفظ المهمة.'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentCourses = context.watch<StudentCoursesProvider>();
    final currentCourses = studentCourses.currentCourses;

    String dateText = 'اختر التاريخ';
    if (selectedDate != null) {
      dateText = DateFormat('yyyy/MM/dd', 'ar').format(selectedDate!);
    }

    String timeText = 'اختر الوقت';
    if (selectedTime != null) {
      if (context.mounted) {
        timeText = selectedTime!.format(context);
      } else {
        timeText = '${selectedTime!.hour}:${selectedTime!.minute}';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AcademiaSubAppBar(
        title: isEditing ? 'تعديل المهمة' : 'إضافة مهمة جديدة',
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Form Field
                const Text(
                  'عنوان المهمة *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'مثال: تسليم تقرير المختبر',
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال عنوان المهمة.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.medium),

                // Description Form Field
                const Text(
                  'الوصف أو الملاحظات',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  textDirection: TextDirection.rtl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'اكتب تفاصيل أو متطلبات المهمة هنا...',
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.all(AppSpacing.medium),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),

                // Linked Course Dropdown Selector
                const Text(
                  'المساق المرتبط',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedEnrollmentId,
                  isExpanded: true,
                  hint: const Text('اختر مساقاً'),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: 10),
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
                      child: Text('بدون مساق'),
                    ),
                    ...currentCourses.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.enrollment.id,
                        child: Text('${c.courseCode} - ${c.title}'),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => selectedEnrollmentId = value),
                ),
                const SizedBox(height: AppSpacing.medium),

                // Date & Time Picker triggers
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'التاريخ',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppColors.borderLight),
                                borderRadius: BorderRadius.circular(AppRadius.input),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(dateText)),
                                  if (selectedDate != null)
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.danger),
                                      onPressed: () => setState(() {
                                        selectedDate = null;
                                        selectedTime = null;
                                      }),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الوقت',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: selectedDate == null ? null : _selectTime,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedDate == null ? AppColors.background : Colors.white,
                                border: Border.all(color: AppColors.borderLight),
                                borderRadius: BorderRadius.circular(AppRadius.input),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 20, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      timeText,
                                      style: TextStyle(
                                        color: selectedDate == null ? AppColors.textDisabled : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),

                // Priority Selection row
                const Text(
                  'الأولوية',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: TaskPriority.values.map((priority) {
                    final isSelected = selectedPriority == priority;
                    String label;
                    Color color;
                    switch (priority) {
                      case TaskPriority.high:
                        label = 'عالية';
                        color = AppColors.danger;
                        break;
                      case TaskPriority.medium:
                        label = 'متوسطة';
                        color = AppColors.warning;
                        break;
                      case TaskPriority.low:
                        label = 'منخفضة';
                        color = AppColors.textMuted;
                        break;
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => selectedPriority = priority);
                          },
                          selectedColor: color,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? color : AppColors.borderLight,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.medium),

                // Type Selection Row
                const Text(
                  'نوع المهمة',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: TaskType.values.map((type) {
                    final isSelected = selectedType == type;
                    String label;
                    switch (type) {
                      case TaskType.assignment:
                        label = 'واجب';
                        break;
                      case TaskType.lecture:
                        label = 'محاضرة';
                        break;
                      case TaskType.study:
                        label = 'دراسة';
                        break;
                      case TaskType.exam:
                        label = 'اختبار';
                        break;
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => selectedType = type);
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.borderLight,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.large),

                // Submit Button
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
                  onPressed: _isSaving ? null : () => _save(currentCourses),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? 'حفظ التعديلات' : 'إضافة المهمة',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
