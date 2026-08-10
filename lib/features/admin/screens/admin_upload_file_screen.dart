import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/cloudinary_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../courses/models/course_offering_model.dart';
import '../../files/models/course_file_model.dart';
import '../../files/providers/course_file_provider.dart';
import '../../files/services/course_file_picker.dart';
import '../widgets/admin_access_guard.dart';
import '../widgets/admin_back_button.dart';

/// وسيطات الشاشة: الطرح الذي يُرفع الملف له.
class UploadFileArgs {
  const UploadFileArgs({required this.offering, required this.courseTitle});

  final CourseOfferingModel offering;
  final String courseTitle;
}

/// رفع ملف لطرح مساق.
///
/// الشاشة لا تعرف Cloudinary ولا Firestore: تجمع العنوان والوصف والتصنيف
/// والملف، ثم تسلّمها إلى CourseFileProvider مع الطرح كاملًا. معرّفات
/// المساق والفصل والطرح تُشتق هناك، فلا تستطيع هذه الشاشة تركيب ملف منسوب
/// إلى فصل خاطئ.
class AdminUploadFileScreen extends StatefulWidget {
  const AdminUploadFileScreen({super.key, this.picker});

  /// منتقي الملفات. يُحقن في الاختبارات ببديل يعيد ملفًا مصطنعًا.
  final CourseFilePickerFn? picker;

  @override
  State<AdminUploadFileScreen> createState() => _AdminUploadFileScreenState();
}

class _AdminUploadFileScreenState extends State<AdminUploadFileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = CourseFileModel.categoryLecture;
  PickedCourseFile? _picked;
  String? _fileError;

  UploadFileArgs? _args;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is UploadFileArgs) _args = arguments;

    _initialized = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picker = widget.picker ?? pickCourseFile;
    final picked = await picker();
    if (picked == null || !mounted) return;

    /*
     * التحقق هنا بثوابت CloudinaryConfig نفسها التي يستعملها المزوّد
     * والخدمة — لا أرقام ولا قوائم صيغ مكتوبة في الشاشة. الفائدة أن المشرف
     * يعرف فورًا أن الملف غير صالح بدل أن ينتظر فشل الرفع.
     */
    if (!CloudinaryConfig.isAllowedExtension(picked.extension)) {
      setState(() {
        _picked = null;
        _fileError = AppStrings.fileTypeNotAllowed;
      });
      return;
    }

    if (!CloudinaryConfig.isWithinSizeLimit(picked.size)) {
      setState(() {
        _picked = null;
        _fileError = picked.size <= 0
            ? AppStrings.fileEmptyError
            : AppStrings.fileTooLargeError;
      });
      return;
    }

    setState(() {
      _picked = picked;
      _fileError = null;
      // عنوان مبدئي من اسم الملف، يبقى قابلًا للتعديل.
      if (_titleController.text.trim().isEmpty) {
        final dot = picked.fileName.lastIndexOf('.');
        _titleController.text = dot > 0
            ? picked.fileName.substring(0, dot)
            : picked.fileName;
      }
    });
  }

  Future<void> _submit() async {
    final args = _args;
    final picked = _picked;
    if (args == null) return;

    if (picked == null) {
      setState(() => _fileError = AppStrings.noFileSelected);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<CourseFileProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await provider.uploadFile(
      offering: args.offering,
      bytes: picked.bytes,
      fileName: picked.fileName,
      title: _titleController.text.trim(),
      category: _category,
      description: _descriptionController.text.trim(),
      mimeType: picked.mimeType,
    );

    if (!mounted) return;

    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.fileUploadedSuccess)),
      );
      // القائمة تستمع إلى Firestore، فالمستند الجديد يظهر من تلقائه.
      Navigator.of(context).pop();
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? AppStrings.fileUploadError),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseFileProvider>();
    final args = _args;

    if (args == null) {
      return const AdminAccessGuard(
        child: Scaffold(body: Center(child: Text(AppStrings.offeringNotFound))),
      );
    }

    final isUploading = provider.isUploading;

    return AdminAccessGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.uploadFileTitle),
          centerTitle: true,
          leading: const AdminBackButton(),
        ),
        body: AbsorbPointer(
          // يمنع أي تفاعل أثناء الرفع، ومنه إرسال ثانٍ.
          absorbing: isUploading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOfferingCard(args),
                  const SizedBox(height: AppSpacing.medium),
                  _buildFileCard(isUploading),
                  const SizedBox(height: AppSpacing.medium),
                  _buildMetadataCard(),
                  const SizedBox(height: AppSpacing.extraLarge),

                  if (isUploading) ...[
                    // حالة غير محدَّدة: لا نملك نسبة تقدّم حقيقية، واختلاقها
                    // يوهم المشرف بدقة غير موجودة.
                    const LinearProgressIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surfaceSecondary,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      AppStrings.fileUploadingLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                  ],

                  AppPrimaryButton(
                    label: AppStrings.confirmUploadAction,
                    isLoading: isUploading,
                    isEnabled: !isUploading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  OutlinedButton(
                    onPressed: isUploading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.cancelAction),
                  ),
                  const SizedBox(height: AppSpacing.large),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfferingCard(UploadFileArgs args) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            args.courseTitle,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${AppStrings.offeringSectionLabel} ${args.offering.section}'
            ' • ${args.offering.instructorName}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(bool isUploading) {
    final picked = _picked;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            picked == null ? AppStrings.noFileSelected : picked.fileName,
            style: AppTextStyles.bodyMedium.copyWith(
              color: picked == null
                  ? AppColors.textMuted
                  : AppColors.textPrimary,
              fontWeight: picked == null ? FontWeight.normal : FontWeight.bold,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (picked != null) ...[
            const SizedBox(height: 4),
            Text(
              _readableSize(picked.size),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ],
          if (_fileError != null) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              _fileError!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.right,
            ),
          ],
          const SizedBox(height: AppSpacing.small),
          OutlinedButton.icon(
            onPressed: isUploading ? null : _pickFile,
            icon: const Icon(Icons.attach_file_rounded, size: 18),
            label: Text(
              picked == null
                  ? AppStrings.selectFileAction
                  : AppStrings.changeFileAction,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            // القيود تُقرأ من الإعداد لا من نص مكتوب يدويًا.
            AppStrings.fileConstraintsNote(
              CloudinaryConfig.maxFileSizeBytes ~/ (1024 * 1024),
              CloudinaryConfig.allowedExtensions.join('، '),
            ),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              labelText: AppStrings.courseFileTitleLabel,
              hintText: AppStrings.courseFileTitleHint,
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
            // القيم المخزَّنة من النموذج؛ العربية للعرض فقط.
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
        ],
      ),
    );
  }

  String _readableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
