import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';
import '../../courses/models/course_model.dart';
import '../../courses/providers/course_provider.dart';

class AdminCourseFormScreen extends StatefulWidget {
  const AdminCourseFormScreen({super.key});

  @override
  State<AdminCourseFormScreen> createState() => _AdminCourseFormScreenState();
}

class _AdminCourseFormScreenState extends State<AdminCourseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructorController = TextEditingController();
  final _departmentController = TextEditingController();
  final _semesterController = TextEditingController();
  final _academicYearController = TextEditingController();

  int _selectedCreditHours = 3;
  String _selectedStatus = 'active';

  CourseModel? _editingCourse;
  bool _isEditMode = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final course = ModalRoute.of(context)?.settings.arguments as CourseModel?;
      if (course != null) {
        _editingCourse = course;
        _isEditMode = true;
        _titleController.text = course.title;
        _codeController.text = course.courseCode;
        _descriptionController.text = course.description;
        _instructorController.text = course.instructorName;
        _departmentController.text = course.department;
        _semesterController.text = course.semester.toString();
        _academicYearController.text = course.academicYear;
        _selectedCreditHours = course.creditHours;
        _selectedStatus = course.status;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _instructorController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    _academicYearController.dispose();
    super.dispose();
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = context.read<CourseProvider>();
      final course = CourseModel(
        id: _isEditMode ? _editingCourse!.id : '',
        courseCode: _codeController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        instructorName: _instructorController.text.trim(),
        department: _departmentController.text.trim(),
        semester: int.tryParse(_semesterController.text.trim()) ?? 1,
        academicYear: _academicYearController.text.trim(),
        creditHours: _selectedCreditHours,
        status: _selectedStatus,
        createdBy: _isEditMode ? _editingCourse!.createdBy : '',
      );

      bool success;
      if (_isEditMode) {
        success = await provider.updateCourse(course);
      } else {
        success = await provider.createCourse(course);
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode
                    ? AppStrings.courseUpdatedSuccess
                    : AppStrings.courseAddedSuccess,
              ),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? AppStrings.courseSaveError,
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditMode
                ? AppStrings.editCourseLabel
                : AppStrings.addCourseLabel,
          ),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section 1: معلومات المساق
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(AppStrings.courseBasicInfoSection),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: AppSpacing.small),
                      _buildLabel(AppStrings.courseTitleLabel),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.courseTitleHintValue,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.courseTitleRequired;
                          }
                          return null;
                        },
                      ),
                      _buildLabel(AppStrings.courseCodeLabel),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.courseCodeHintValue,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.courseCodeRequired;
                          }
                          return null;
                        },
                      ),
                      _buildLabel(AppStrings.instructorNameLabel),
                      TextFormField(
                        controller: _instructorController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.instructorHintValue,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.instructorRequired;
                          }
                          return null;
                        },
                      ),
                      _buildLabel(AppStrings.departmentLabel),
                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.departmentHintValue,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.departmentRequired;
                          }
                          return null;
                        },
                      ),
                      _buildLabel(AppStrings.courseDescriptionLabel),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: AppStrings.courseDescriptionHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.large),

                // Section 2: معلومات الفصل
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(AppStrings.courseSemesterInfoSection),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: AppSpacing.small),
                      _buildLabel(AppStrings.semesterLabel),
                      TextFormField(
                        controller: _semesterController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: AppStrings.semesterHintValue,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.semesterInvalid;
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return AppStrings.semesterInvalid;
                          }
                          return null;
                        },
                      ),
                      _buildLabel(AppStrings.academicYearLabel),
                      TextFormField(
                        controller: _academicYearController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.academicYearHintValue,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.academicYearRequired;
                          }
                          return null;
                        },
                      ),
                      _buildLabel(AppStrings.creditHoursLabel),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedCreditHours,
                        decoration: const InputDecoration(),
                        items: [1, 2, 3, 4, 5].map((hours) {
                          return DropdownMenuItem<int>(
                            value: hours,
                            child: Text(
                              '$hours ${AppStrings.creditHoursSuffix}',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCreditHours = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.large),

                // Section 3: حالة المساق
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        AppStrings.courseAcademicStatusSection,
                      ),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: AppSpacing.small),
                      _buildLabel(AppStrings.statusLabel),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text(AppStrings.activeStatus),
                          ),
                          DropdownMenuItem(
                            value: 'archived',
                            child: Text(AppStrings.archivedStatus),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedStatus = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),

                // Save and Cancel actions
                AppPrimaryButton(
                  label: _isEditMode
                      ? AppStrings.saveChangesLabel
                      : AppStrings.addCourseLabel,
                  isLoading: provider.isSaving,
                  isEnabled: !provider.isSaving,
                  onPressed: _submitForm,
                ),
                const SizedBox(height: AppSpacing.medium),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(AppStrings.cancelAction),
                ),
                const SizedBox(height: AppSpacing.large),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
