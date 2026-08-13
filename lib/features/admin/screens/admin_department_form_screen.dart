import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../academics/models/department_model.dart';
import '../../academics/providers/academic_structure_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// شاشة واحدة تخدم الإنشاء والتعديل معًا.
///
/// يُمرَّر DepartmentModel عبر arguments للتعديل، ويُترك فارغًا للإنشاء.
class AdminDepartmentFormScreen extends StatefulWidget {
  const AdminDepartmentFormScreen({super.key});

  @override
  State<AdminDepartmentFormScreen> createState() =>
      _AdminDepartmentFormScreenState();
}

class _AdminDepartmentFormScreenState extends State<AdminDepartmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  String _selectedStatus = DepartmentModel.statusActive;

  DepartmentModel? _editing;
  bool _isEditMode = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is DepartmentModel) {
      _editing = arguments;
      _isEditMode = true;
      _nameController.text = arguments.name;
      _codeController.text = arguments.code;
      _selectedStatus = arguments.status;
    }

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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<AcademicStructureProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final department = DepartmentModel(
      id: _isEditMode ? _editing!.id : '',
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      status: _selectedStatus,
      source: _isEditMode ? _editing!.source : DepartmentModel.sourceManual,
      externalId: _isEditMode ? _editing!.externalId : null,
    );

    final success = _isEditMode
        ? await provider.updateDepartment(department)
        : await provider.createDepartment(department);

    if (!mounted) return;

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? AppStrings.departmentUpdatedSuccess
                : AppStrings.departmentAddedSuccess,
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? AppStrings.departmentSaveError,
          ),
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
            _isEditMode
                ? AppStrings.editDepartmentLabel
                : AppStrings.addDepartmentLabel,
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
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(AppStrings.departmentNameLabel),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.departmentHintValue,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.departmentNameRequired;
                          }
                          return null;
                        },
                      ),

                      _buildLabel(AppStrings.departmentCodeLabel),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.departmentCodeHint,
                        ),
                      ),

                      _buildLabel(AppStrings.statusLabel),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        items: const [
                          DropdownMenuItem(
                            value: DepartmentModel.statusActive,
                            child: Text(AppStrings.activeStatus),
                          ),
                          DropdownMenuItem(
                            value: DepartmentModel.statusArchived,
                            child: Text(AppStrings.archivedStatus),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedStatus = value);
                        },
                        validator: (value) {
                          if (value == null ||
                              !DepartmentModel.allowedStatuses.contains(value)) {
                            return AppStrings.departmentStatusInvalid;
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
                      : AppStrings.addDepartmentLabel,
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
