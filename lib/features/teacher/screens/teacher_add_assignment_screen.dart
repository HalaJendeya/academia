import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../assignments/models/course_assignment_model.dart';
import '../../assignments/providers/course_assignment_provider.dart';
import '../models/teacher_offering_view.dart';
import '../providers/teacher_offerings_provider.dart';
import '../widgets/teacher_access_guard.dart';
import 'teacher_assignments_screen.dart';

/// شاشة واحدة تخدم إنشاء الواجب وتعديله.
///
/// قائمة الطروح مقصورة على ما يملكه المعلّم فعلًا؛ لا تُستعلم الطروح
/// اعتباطيًا. وعند التعديل يُقفل الطرح: نقل واجب بين الطروح ممنوع في
/// الخدمة والقواعد معًا، فعرضه قابلًا للتغيير وعدٌ لا يمكن الوفاء به.
class TeacherAddAssignmentScreen extends StatefulWidget {
  const TeacherAddAssignmentScreen({super.key});

  @override
  State<TeacherAddAssignmentScreen> createState() =>
      _TeacherAddAssignmentScreenState();
}

class _TeacherAddAssignmentScreenState
    extends State<TeacherAddAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedOfferingId;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String _priority = CourseAssignmentModel.priorityMedium;

  CourseAssignmentModel? _editing;
  bool _isEditMode = false;
  bool _initialized = false;

  /// خطأ التحقق من الموعد. TextFormField لا يمثّل منتقيات التاريخ والوقت،
  /// فيُدار خطؤها يدويًا بدل تركها تمرّ صامتة.
  String? _dueError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is TeacherAssignmentFormArgs && arguments.assignment != null) {
      final assignment = arguments.assignment!;
      _editing = assignment;
      _isEditMode = true;
      _selectedOfferingId = assignment.offeringId;
      _titleController.text = assignment.title;
      _descriptionController.text = assignment.description;
      _dueDate = DateTime(
        assignment.dueAt.year,
        assignment.dueAt.month,
        assignment.dueAt.day,
      );
      _dueTime = TimeOfDay(
        hour: assignment.dueAt.hour,
        minute: assignment.dueAt.minute,
      );
      _priority = assignment.priority;
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime? get _dueAt {
    final date = _dueDate;
    final time = _dueTime;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dueDate ?? now.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      // الماضي مسموح عند التعديل: واجب مضى موعده يبقى قابلًا للتصحيح.
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ar'),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _dueDate = picked;
      _dueError = null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 23, minute: 59),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _dueTime = picked;
      _dueError = null;
    });
  }

  Future<void> _submit() async {
    final provider = context.read<CourseAssignmentProvider>();

    // حارس ضد الإرسال المزدوج: نقرتان سريعتان تنتجان واجبين.
    if (provider.isSaving) return;

    final formValid = _formKey.currentState?.validate() ?? false;
    final dueAt = _dueAt;

    setState(() {
      _dueError = dueAt == null ? AppStrings.assignmentDeadlineRequired : null;
    });

    if (!formValid || dueAt == null) return;

    final offeringId = _selectedOfferingId;
    if (offeringId == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = _isEditMode
        ? await provider.updateAssignment(
            assignmentId: _editing!.id,
            title: _titleController.text,
            description: _descriptionController.text,
            dueAt: dueAt,
            priority: _priority,
          )
        : await provider.createAssignment(
            offeringId: offeringId,
            title: _titleController.text,
            description: _descriptionController.text,
            dueAt: dueAt,
            priority: _priority,
          );

    if (!mounted) return;

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? AppStrings.assignmentUpdatedSuccess
                : AppStrings.assignmentCreatedSuccess,
          ),
        ),
      );
      navigator.pop();
    } else {
      // البيانات المُدخلة تبقى كما هي حتى يصحّح المعلّم ويعيد المحاولة.
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? AppStrings.assignmentSaveError),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 10.0),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offeringsProvider = context.watch<TeacherOfferingsProvider>();
    final provider = context.watch<CourseAssignmentProvider>();

    // الطروح النشطة وحدها تقبل واجبًا جديدًا؛ المؤرشف يبقى معروضًا عند
    // تعديل واجب قديم يخصّه.
    final selectable = offeringsProvider.offerings
        .where((view) => view.isActive || view.offeringId == _selectedOfferingId)
        .toList();

    return TeacherAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditMode
                ? AppStrings.editAssignmentTitle
                : AppStrings.addAssignmentTitle,
          ),
          centerTitle: true,
        ),
        body: selectable.isEmpty
            ? const AppEmptyState(
                title: AppStrings.teacherAssignmentsNoOfferingsTitle,
                description: AppStrings.teacherAssignmentsNoOfferingsDesc,
                icon: Icons.menu_book_outlined,
              )
            : _buildForm(selectable, provider),
      ),
    );
  }

  Widget _buildForm(
    List<TeacherOfferingView> selectable,
    CourseAssignmentProvider provider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(AppStrings.assignmentOfferingLabel),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOfferingId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: AppStrings.assignmentOfferingHint,
                      prefixIcon: Icon(Icons.menu_book_rounded),
                    ),
                    items: [
                      for (final view in selectable)
                        DropdownMenuItem<String>(
                          value: view.offeringId,
                          child: Text(
                            '${view.displayTitle} · '
                            '${AppStrings.offeringSectionLabel} '
                            '${view.section}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    // الطرح جزء من هوية الواجب: يُقفل بعد الإنشاء.
                    onChanged: _isEditMode
                        ? null
                        : (value) =>
                              setState(() => _selectedOfferingId = value),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.assignmentCourseRequired;
                      }
                      return null;
                    },
                  ),

                  _buildLabel(AppStrings.assignmentTitleLabel),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: AppStrings.assignmentTitleHint,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.assignmentTitleRequired;
                      }
                      return null;
                    },
                  ),

                  _buildLabel(AppStrings.assignmentInstructionsLabel),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: AppStrings.assignmentInstructionsHint,
                    ),
                    maxLines: 4,
                    // التعليمات اختيارية: واجب بعنوان واضح قد لا يحتاج شرحًا.
                  ),

                  _buildLabel(AppStrings.assignmentDueDateLabel),
                  _buildPickerTile(
                    icon: Icons.event_rounded,
                    value: _dueDate == null
                        ? AppStrings.assignmentDueDatePickHint
                        : DateFormat('yyyy/MM/dd', 'ar').format(_dueDate!),
                    isPlaceholder: _dueDate == null,
                    onTap: _pickDate,
                  ),

                  _buildLabel(AppStrings.assignmentDueTimeLabel),
                  _buildPickerTile(
                    icon: Icons.schedule_rounded,
                    value: _dueTime == null
                        ? AppStrings.assignmentDueTimePickHint
                        : _dueTime!.format(context),
                    isPlaceholder: _dueTime == null,
                    onTap: _pickTime,
                  ),

                  if (_dueError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _dueError!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],

                  _buildLabel(AppStrings.assignmentPriorityLabel),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: CourseAssignmentModel.priorityLow,
                        child: Text(AppStrings.assignmentPriorityLow),
                      ),
                      DropdownMenuItem(
                        value: CourseAssignmentModel.priorityMedium,
                        child: Text(AppStrings.assignmentPriorityMedium),
                      ),
                      DropdownMenuItem(
                        value: CourseAssignmentModel.priorityHigh,
                        child: Text(AppStrings.assignmentPriorityHigh),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _priority = value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.extraLarge),

            AppPrimaryButton(
              label: _isEditMode
                  ? AppStrings.saveChanges
                  : AppStrings.assignmentSaveNewAction,
              isLoading: provider.isSaving,
              isEnabled: !provider.isSaving,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.medium),
            OutlinedButton(
              onPressed: provider.isSaving
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text(AppStrings.cancelAction),
            ),
            const SizedBox(height: AppSpacing.large),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String value,
    required bool isPlaceholder,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(prefixIcon: Icon(icon)),
        child: Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isPlaceholder
                ? AppColors.textMuted
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
