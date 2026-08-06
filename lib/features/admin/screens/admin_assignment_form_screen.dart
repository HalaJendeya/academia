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
import '../../courses/providers/course_provider.dart';

class AdminAssignmentFormScreen extends StatefulWidget {
  const AdminAssignmentFormScreen({super.key});

  @override
  State<AdminAssignmentFormScreen> createState() =>
      _AdminAssignmentFormScreenState();
}

class _AdminAssignmentFormScreenState extends State<AdminAssignmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCourseId;
  DateTime? _selectedDueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>().courses;

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.addNewAssignmentAction),
          leading: const AdminBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info warning
                AppCard(
                  backgroundColor: AppColors.warning.withValues(alpha: 0.05),
                  borderColor: AppColors.warning.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warningDark,
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Text(
                          AppStrings.assignmentFeatureNotConnected,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.warningDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.large),

                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.assignmentTitleLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.assignmentTitleHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.assignmentTitleRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        AppStrings.assignmentCourseLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCourseId,
                        decoration: const InputDecoration(
                          hintText: AppStrings.assignmentCourseSelectHint,
                        ),
                        items: courses.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.title),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCourseId = val;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return AppStrings.assignmentCourseRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        AppStrings.assignmentDeadlineLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 7),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 180),
                            ),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDueDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.calendar_today_rounded),
                          ),
                          child: Text(
                            _selectedDueDate == null
                                ? AppStrings.assignmentDeadlineHint
                                : _selectedDueDate!.toString().split(' ')[0],
                            style: TextStyle(
                              color: _selectedDueDate == null
                                  ? AppColors.textDisabled
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        AppStrings.assignmentInstructionsLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: AppStrings.assignmentInstructionsHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),

                AppPrimaryButton(
                  label: AppStrings.assignmentSaveAction,
                  isEnabled: false, // mock-only
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.medium),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(AppStrings.cancelAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
