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
import '../../academics/providers/academic_structure_provider.dart';
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

  int _selectedCreditHours = 3;
  String _selectedStatus = CourseModel.statusActive;
  String? _selectedDepartmentId;

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
        _selectedCreditHours = course.creditHours;
        _selectedStatus = course.status;
        _selectedDepartmentId = course.hasDepartment
            ? course.departmentId
            : null;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AcademicStructureProvider>().listenToDepartments();
      });

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /*
   * القيمة الفعلية للقسم المختار.
   *
   * القسم يحل محل الفصل الدراسي والمدرّس في هذه الشاشة: المساق كيان دائم،
   * أما الفصل والمدرّس فيخصّان الطرح وتُدار في شاشة الطروحات.
   *
   * عند تعديل مساق قديم بلا قسم نُرجع null حتى يُجبر التحقق المشرفَ على
   * اختيار قسم قبل الحفظ.
   */
  String? _effectiveDepartmentId(AcademicStructureProvider structureProvider) {
    final selected = _selectedDepartmentId;
    if (selected != null &&
        structureProvider.departmentsById.containsKey(selected)) {
      return selected;
    }
    return null;
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
    final departmentId = _effectiveDepartmentId(
      context.read<AcademicStructureProvider>(),
    );

    if (_formKey.currentState?.validate() ?? false) {
      if (departmentId == null) return;

      final provider = context.read<CourseProvider>();
      final course = CourseModel(
        id: _isEditMode ? _editingCourse!.id : '',
        courseCode: _codeController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        departmentId: departmentId,
        creditHours: _selectedCreditHours,
        status: _selectedStatus,
        createdBy: _isEditMode ? _editingCourse!.createdBy : '',
        source: _isEditMode ? _editingCourse!.source : CourseModel.sourceManual,
        externalId: _isEditMode ? _editingCourse!.externalId : null,
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

  /// لا يمكن إنشاء مساق قبل وجود قسم أكاديمي واحد على الأقل.
  ///
  /// شاشة إدارة الأقسام ما زالت ضمن المرحلة 7D، لذلك تعرض هذه الحالة الرسالة
  /// دون إجراء انتقال إلى شاشة غير موجودة بعد.
  Widget _buildNoDepartmentsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: AppCard(
          backgroundColor: AppColors.warning.withValues(alpha: 0.05),
          borderColor: AppColors.warning.withValues(alpha: 0.2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.domain_disabled_rounded,
                size: 48,
                color: AppColors.warningDark,
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                AppStrings.noDepartmentsForCourseTitle,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warningDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                AppStrings.noDepartmentsForCourseDesc,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final structureProvider = context.watch<AcademicStructureProvider>();

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
        body: structureProvider.departments.isEmpty
            ? _buildNoDepartmentsState()
            : SingleChildScrollView(
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
                      /*
                       * التفرّد لا يمكن التحقق منه في النموذج: قواعد Firestore
                       * لا تنفّذ استعلامات، لذلك يفحصه CourseService عند الحفظ
                       * ويعود الخطأ رسالةً واضحة. نوضّح القاعدة هنا مسبقًا.
                       */
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.courseCodeUniqueNote,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
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

                // Section 2: القسم والساعات المعتمدة
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(AppStrings.courseAcademicInfoSection),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: AppSpacing.small),
                      _buildLabel(AppStrings.courseDepartmentLabel),
                      DropdownButtonFormField<String>(
                        initialValue: _effectiveDepartmentId(structureProvider),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: AppStrings.courseDepartmentSelectHint,
                        ),
                        items: structureProvider.departments.map((department) {
                          return DropdownMenuItem<String>(
                            value: department.id,
                            child: Text(
                              department.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartmentId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.courseDepartmentRequired;
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
