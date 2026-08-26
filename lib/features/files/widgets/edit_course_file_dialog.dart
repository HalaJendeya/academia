import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/course_file_model.dart';

/// تعديل البيانات الوصفية لملف.
///
/// الحقول القابلة للتعديل هي الوصفية وحدها. الطرح ومراجع Cloudinary ورافع
/// الملف لا تظهر هنا ولا يمكن تغييرها: تعديلها يعني ملفًا آخر، وهو ما يُنشأ
/// برفع جديد. النموذج المُعاد مبني بـ copyWith فوق الأصل، فلا يمكن للحوار
/// أن يمسّ حقلًا لا يعرضه.
Future<CourseFileModel?> showEditCourseFileDialog({
  required BuildContext context,
  required CourseFileModel file,
}) {
  return showDialog<CourseFileModel>(
    context: context,
    builder: (dialogContext) => _EditCourseFileDialog(file: file),
  );
}

class _EditCourseFileDialog extends StatefulWidget {
  const _EditCourseFileDialog({required this.file});

  final CourseFileModel file;

  @override
  State<_EditCourseFileDialog> createState() => _EditCourseFileDialogState();
}

class _EditCourseFileDialogState extends State<_EditCourseFileDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController = TextEditingController(
    text: widget.file.title,
  );
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.file.description);

  late String _category = widget.file.category;
  late String _status = widget.file.status;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        AppStrings.editFileTitle,
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.right,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // اسم الملف الأصلي للتذكير فقط، غير قابل للتعديل.
              Text(
                widget.file.fileName,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.medium),

              TextFormField(
                controller: _titleController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: AppStrings.courseFileTitleLabel,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.courseFileTitleRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.small),

              TextFormField(
                controller: _descriptionController,
                textAlign: TextAlign.right,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: AppStrings.fileDescriptionLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.small),

              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.fileCategoryLabel,
                ),
                items: CourseFileModel.allowedCategories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          AppStrings.fileCategoryDisplay(category),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _category = value);
                },
              ),
              const SizedBox(height: AppSpacing.small),

              DropdownButtonFormField<String>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.fileStatusLabel,
                ),
                items: const [
                  DropdownMenuItem(
                    value: CourseFileModel.statusActive,
                    child: Text(AppStrings.fileStatusActive),
                  ),
                  DropdownMenuItem(
                    value: CourseFileModel.statusArchived,
                    child: Text(AppStrings.fileStatusArchived),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _status = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop(
                widget.file.copyWith(
                  title: _titleController.text.trim(),
                  description: _descriptionController.text.trim(),
                  category: _category,
                  status: _status,
                ),
              );
            },
            child: const Text(AppStrings.saveChanges),
          ),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancelAction),
        ),
      ],
    );
  }
}
