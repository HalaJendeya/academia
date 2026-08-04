import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn || !auth.isAdmin) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });
  }

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
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
      child: Text(
        text,
        style: AppTextStyles.titleSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = context.read<CourseProvider>();
      final auth = context.read<AuthProvider>();

      final currentUid = auth.currentUser?.uid ?? '';

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
        createdBy: _isEditMode ? _editingCourse!.createdBy : currentUid,
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
    final auth = context.watch<AuthProvider>();

    // Guard: Redirect non-admin
    if (!auth.isLoggedIn || !auth.isAdmin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final provider = context.watch<CourseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? AppStrings.editCourseLabel : AppStrings.addCourseLabel,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Course Title
              _buildLabel(AppStrings.courseTitleLabel),
              TextFormField(
                controller: _titleController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'مثال: إدارة قواعد البيانات',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.courseTitleRequired;
                  }
                  return null;
                },
              ),

              // Course Code
              _buildLabel(AppStrings.courseCodeLabel),
              TextFormField(
                controller: _codeController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'مثال: MIS4310',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.courseCodeRequired;
                  }
                  return null;
                },
              ),

              // Description
              _buildLabel(AppStrings.courseDescriptionLabel),
              TextFormField(
                controller: _descriptionController,
                textAlign: TextAlign.right,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب وصفاً مختصراً للمساق...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
              ),

              // Instructor Name
              _buildLabel(AppStrings.instructorNameLabel),
              TextFormField(
                controller: _instructorController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'مثال: د. أحمد محمد',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.instructorRequired;
                  }
                  return null;
                },
              ),

              // Department
              _buildLabel(AppStrings.departmentLabel),
              TextFormField(
                controller: _departmentController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'مثال: نظم المعلومات الإدارية',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.departmentRequired;
                  }
                  return null;
                },
              ),

              // Semester
              _buildLabel(AppStrings.semesterLabel),
              TextFormField(
                controller: _semesterController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'مثال: 7',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
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

              // Academic Year
              _buildLabel(AppStrings.academicYearLabel),
              TextFormField(
                controller: _academicYearController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'مثال: 2025-2026',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.academicYearRequired;
                  }
                  return null;
                },
              ),

              // Credit Hours (Dropdown selector)
              _buildLabel(AppStrings.creditHoursLabel),
              DropdownButtonFormField<int>(
                initialValue: _selectedCreditHours,
                alignment: Alignment.centerRight,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                items: [1, 2, 3, 4, 5].map((hours) {
                  return DropdownMenuItem<int>(
                    value: hours,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('$hours ساعات معتمدة'),
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

              // Status (Dropdown active/archived)
              _buildLabel(AppStrings.statusLabel),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                alignment: Alignment.centerRight,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'active',
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(AppStrings.activeStatus),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'archived',
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(AppStrings.archivedStatus),
                    ),
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

              const SizedBox(height: AppSpacing.large),

              // Submit Button
              AppPrimaryButton(
                label: _isEditMode
                    ? AppStrings.saveChangesLabel
                    : AppStrings.addCourseLabel,
                isLoading: provider.isSaving,
                isEnabled: !provider.isSaving,
                onPressed: _submitForm,
              ),
              const SizedBox(height: AppSpacing.large),
            ],
          ),
        ),
      ),
    );
  }
}
