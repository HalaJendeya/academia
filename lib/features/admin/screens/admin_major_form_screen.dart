import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../academics/models/major_model.dart';
import '../../academics/providers/academic_structure_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// شاشة واحدة تخدم الإنشاء والتعديل معًا.
///
/// يُمرَّر MajorModel عبر arguments للتعديل، ويُترك فارغًا للإنشاء.
class AdminMajorFormScreen extends StatefulWidget {
  const AdminMajorFormScreen({super.key});

  @override
  State<AdminMajorFormScreen> createState() => _AdminMajorFormScreenState();
}

class _AdminMajorFormScreenState extends State<AdminMajorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  String? _selectedDepartmentId;
  int _selectedTotalLevels = MajorModel.defaultTotalLevels;
  String _selectedStatus = MajorModel.statusActive;

  MajorModel? _editing;
  bool _isEditMode = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is MajorModel) {
      _editing = arguments;
      _isEditMode = true;
      _nameController.text = arguments.name;
      _codeController.text = arguments.code;
      _selectedDepartmentId = arguments.departmentId;
      _selectedTotalLevels = arguments.totalLevels;
      _selectedStatus = arguments.status;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicStructureProvider>().listenToDepartments();
    });

    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
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

  /// القسم المختار فقط إذا كان موجودًا فعلًا في القائمة المحمَّلة.
  String? _effectiveDepartmentId(AcademicStructureProvider provider) {
    final selected = _selectedDepartmentId;
    if (selected != null && provider.departmentsById.containsKey(selected)) {
      return selected;
    }
    return null;
  }

  Future<void> _submit() async {
    final provider = context.read<AcademicStructureProvider>();
    final departmentId = _effectiveDepartmentId(provider);

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (departmentId == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final major = MajorModel(
      id: _isEditMode ? _editing!.id : '',
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      departmentId: departmentId,
      totalLevels: _selectedTotalLevels,
      status: _selectedStatus,
      source: _isEditMode ? _editing!.source : MajorModel.sourceManual,
      externalId: _isEditMode ? _editing!.externalId : null,
    );

    final success = _isEditMode
        ? await provider.updateMajor(major)
        : await provider.createMajor(major);

    if (!mounted) return;

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? AppStrings.majorUpdatedSuccess
                : AppStrings.majorAddedSuccess,
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? AppStrings.majorSaveError),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicStructureProvider>();

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditMode ? AppStrings.editMajorLabel : AppStrings.addMajorLabel,
          ),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        body: provider.departments.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Text(
                    AppStrings.noDepartmentsDesc,
                    style: TextStyle(color: AppColors.warningDark),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : SingleChildScrollView(
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
                            _buildLabel(AppStrings.majorNameLabel),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: AppStrings.majorNameLabel,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppStrings.majorNameRequired;
                                }
                                return null;
                              },
                            ),

                            _buildLabel(AppStrings.majorCodeLabel),
                            TextFormField(
                              controller: _codeController,
                              decoration: const InputDecoration(
                                hintText: AppStrings.majorCodeHint,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppStrings.majorCodeRequired;
                                }
                                return null;
                              },
                            ),

                            _buildLabel(AppStrings.courseDepartmentLabel),
                            DropdownButtonFormField<String>(
                              initialValue: _effectiveDepartmentId(provider),
                              isExpanded: true,
                              decoration: const InputDecoration(
                                hintText: AppStrings.courseDepartmentSelectHint,
                              ),
                              items: provider.departments
                                  .map(
                                    (department) => DropdownMenuItem<String>(
                                      value: department.id,
                                      child: Text(
                                        department.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _selectedDepartmentId = value);
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppStrings.courseDepartmentRequired;
                                }
                                return null;
                              },
                            ),

                            _buildLabel(AppStrings.majorTotalLevelsLabel),
                            DropdownButtonFormField<int>(
                              initialValue: _selectedTotalLevels,
                              items: AppStrings.academicLevelValues
                                  .map(
                                    (levels) => DropdownMenuItem<int>(
                                      value: levels,
                                      child: Text(
                                        '$levels ${AppStrings.levelsSuffix}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedTotalLevels = value);
                              },
                            ),

                            _buildLabel(AppStrings.statusLabel),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              items: const [
                                DropdownMenuItem(
                                  value: MajorModel.statusActive,
                                  child: Text(AppStrings.activeStatus),
                                ),
                                DropdownMenuItem(
                                  value: MajorModel.statusArchived,
                                  child: Text(AppStrings.archivedStatus),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedStatus = value);
                              },
                              validator: (value) {
                                if (value == null ||
                                    !MajorModel.allowedStatuses.contains(
                                      value,
                                    )) {
                                  return AppStrings.majorStatusInvalid;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.extraLarge),

                      AppPrimaryButton(
                        label: _isEditMode
                            ? AppStrings.saveChanges
                            : AppStrings.addMajorLabel,
                        isLoading: provider.isSaving,
                        isEnabled: !provider.isSaving,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
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
