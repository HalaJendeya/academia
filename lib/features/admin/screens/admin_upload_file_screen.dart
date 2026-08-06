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

class AdminUploadFileScreen extends StatefulWidget {
  const AdminUploadFileScreen({super.key});

  @override
  State<AdminUploadFileScreen> createState() => _AdminUploadFileScreenState();
}

class _AdminUploadFileScreenState extends State<AdminUploadFileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _selectedCourseId;
  String? _selectedFileName;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>().courses;

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.uploadNewFileAction),
          leading: const AdminBackButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning info banner
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
                          AppStrings.uploadFeatureNotConnected,
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
                        AppStrings.fileTitleLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.fileTitleHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.fileTitleRequired;
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
                        AppStrings.attachedFileLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          // mock picking a file
                          setState(() {
                            _selectedFileName = 'lecture_presentation.pdf';
                          });
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.attach_file_rounded),
                          ),
                          child: Text(
                            _selectedFileName ?? AppStrings.filePickerPrompt,
                            style: TextStyle(
                              color: _selectedFileName == null
                                  ? AppColors.textDisabled
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),

                AppPrimaryButton(
                  label: AppStrings.uploadFileAction,
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
