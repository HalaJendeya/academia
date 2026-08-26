import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../semesters/models/semester_model.dart';
import '../../semesters/providers/semester_provider.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// شاشة واحدة تخدم الإنشاء والتعديل معًا.
///
/// تُمرَّر SemesterModel عبر arguments للتعديل، وتُترك فارغة للإنشاء.
class AdminSemesterFormScreen extends StatefulWidget {
  const AdminSemesterFormScreen({super.key});

  @override
  State<AdminSemesterFormScreen> createState() =>
      _AdminSemesterFormScreenState();
}

class _AdminSemesterFormScreenState extends State<AdminSemesterFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _academicYearController = TextEditingController();
  final _semesterNumberController = TextEditingController();
  final _semesterNameController = TextEditingController();

  String _selectedStatus = SemesterModel.statusUpcoming;
  DateTime? _startDate;
  DateTime? _endDate;

  SemesterModel? _editingSemester;
  bool _isEditMode = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is SemesterModel) {
      _editingSemester = arguments;
      _isEditMode = true;
      _academicYearController.text = arguments.academicYear;
      _semesterNumberController.text = arguments.semesterNumber.toString();
      _semesterNameController.text = arguments.semesterName;
      _selectedStatus = arguments.status;
      _startDate = arguments.startDate;
      _endDate = arguments.endDate;
    }

    // تحديث المعرّف المعروض أثناء الكتابة في وضع الإنشاء.
    _academicYearController.addListener(_refresh);
    _semesterNumberController.addListener(_refresh);

    _initialized = true;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _academicYearController.removeListener(_refresh);
    _semesterNumberController.removeListener(_refresh);
    _academicYearController.dispose();
    _semesterNumberController.dispose();
    _semesterNameController.dispose();
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

  String get _previewId {
    final year = _academicYearController.text.trim();
    final number = int.tryParse(_semesterNumberController.text.trim());
    if (year.isEmpty || number == null || number <= 0) return '—';
    return SemesterModel.buildId(year, number);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppStrings.selectDatePrompt;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial =
        (isStart ? _startDate : _endDate) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<SemesterProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final academicYear = _academicYearController.text.trim();
    final semesterNumber =
        int.tryParse(_semesterNumberController.text.trim()) ?? 1;

    final semester = SemesterModel(
      id: _isEditMode
          ? _editingSemester!.id
          : SemesterModel.buildId(academicYear, semesterNumber),
      academicYear: academicYear,
      semesterNumber: semesterNumber,
      semesterName: _semesterNameController.text.trim(),
      status: _selectedStatus,
      startDate: _startDate,
      endDate: _endDate,
      source: _isEditMode
          ? _editingSemester!.source
          : SemesterModel.sourceManual,
      externalId: _isEditMode ? _editingSemester!.externalId : null,
    );

    final success = _isEditMode
        ? await provider.updateSemester(semester)
        : await provider.createSemester(semester);

    if (!mounted) return;

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? AppStrings.semesterUpdatedSuccess
                : AppStrings.semesterAddedSuccess,
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? AppStrings.semesterSaveError,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SemesterProvider>();

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditMode
                ? AppStrings.editSemesterLabel
                : AppStrings.addSemesterLabel,
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
                      _buildSectionHeader(AppStrings.semestersManagementTitle),
                      const Divider(color: AppColors.divider),

                      _buildLabel(AppStrings.academicYearOnlyLabel),
                      TextFormField(
                        controller: _academicYearController,
                        keyboardType: TextInputType.number,
                        readOnly: _isEditMode,
                        decoration: const InputDecoration(
                          hintText: AppStrings.academicYearHintOnlyValue,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.academicYearRequired;
                          }
                          return null;
                        },
                      ),

                      _buildLabel(AppStrings.semesterNumberLabel),
                      TextFormField(
                        controller: _semesterNumberController,
                        keyboardType: TextInputType.number,
                        readOnly: _isEditMode,
                        decoration: const InputDecoration(
                          hintText: AppStrings.semesterNumberHintValue,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.semesterNumberInvalid;
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return AppStrings.semesterNumberInvalid;
                          }
                          return null;
                        },
                      ),

                      if (_isEditMode) ...[
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          AppStrings.semesterIdentityLockedNote,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],

                      _buildLabel(AppStrings.semesterNameLabel),
                      TextFormField(
                        controller: _semesterNameController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.semesterNameHintValue,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.semesterNameRequired;
                          }
                          return null;
                        },
                      ),

                      _buildLabel(AppStrings.semesterStatusLabel),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        items: const [
                          DropdownMenuItem(
                            value: SemesterModel.statusUpcoming,
                            child: Text(AppStrings.semesterStatusUpcoming),
                          ),
                          DropdownMenuItem(
                            value: SemesterModel.statusCurrent,
                            child: Text(AppStrings.semesterStatusCurrent),
                          ),
                          DropdownMenuItem(
                            value: SemesterModel.statusCompleted,
                            child: Text(AppStrings.semesterStatusCompleted),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedStatus = value);
                        },
                        validator: (value) {
                          if (value == null ||
                              !SemesterModel.allowedStatuses.contains(value)) {
                            return AppStrings.semesterStatusInvalid;
                          }
                          return null;
                        },
                      ),

                      _buildLabel(AppStrings.semesterStartDateLabel),
                      InkWell(
                        onTap: () => _pickDate(isStart: true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.calendar_today_rounded),
                          ),
                          child: Text(
                            _formatDate(_startDate),
                            style: TextStyle(
                              color: _startDate == null
                                  ? AppColors.textDisabled
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),

                      _buildLabel(AppStrings.semesterEndDateLabel),
                      InkWell(
                        onTap: () => _pickDate(isStart: false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.event_rounded),
                          ),
                          child: Text(
                            _formatDate(_endDate),
                            style: TextStyle(
                              color: _endDate == null
                                  ? AppColors.textDisabled
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),

                      if (!_isEditMode) ...[
                        const SizedBox(height: AppSpacing.medium),
                        const Divider(color: AppColors.divider),
                        Row(
                          children: [
                            const Icon(
                              Icons.tag_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${AppStrings.generatedIdLabel}: ',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _previewId,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.extraLarge),

                AppPrimaryButton(
                  label: _isEditMode
                      ? AppStrings.saveChanges
                      : AppStrings.addSemesterLabel,
                  isLoading: provider.isSaving,
                  isEnabled: !provider.isSaving,
                  onPressed: _submitForm,
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
