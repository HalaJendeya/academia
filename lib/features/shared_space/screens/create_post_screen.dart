
// lib/features/shared_space/screens/create_post_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../files/services/course_file_picker.dart';
import '../models/post_attachment.dart';
import '../providers/post_provider.dart';

/// إنشاء منشور جديد بساحة مشاركة مساق محدد.
///
/// المساق ثابت ومعروف مسبقًا (الشاشة تُفتح من داخل تبويب "المساحة" الخاص
/// بمساق واحد)، فيُعرض كبطاقة معلومات ثابتة لا Dropdown وهمي بخيار واحد —
/// نفس مبدأ بطاقة المساق في AdminUploadFileScreen.
///
/// اختيار المرفق حقيقي (نفس pickCourseFile المستخدَمة بميزة ملفات
/// المساق)؛ الرفع الفعلي إلى Cloudinary غير موجود بعد بمرحلة الـ Mock —
/// المرفق يُحفظ كبيانات وصفية محلية فقط ضمن المنشور.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  final String courseId;
  final String courseTitle;

  static Route<void> route({
    required String courseId,
    required String courseTitle,
  }) {
    return MaterialPageRoute(
      builder: (_) => CreatePostScreen(
        courseId: courseId,
        courseTitle: courseTitle,
      ),
    );
  }

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  PickedCourseFile? _pickedFile;
  String? _contentError;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final picked = await pickCourseFile();
    if (picked == null || !mounted) return;
    setState(() => _pickedFile = picked);
  }

  void _removeAttachment() {
    setState(() => _pickedFile = null);
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _contentError = 'يرجى كتابة نص المنشور');
      return;
    }
    setState(() => _contentError = null);

    final provider = context.read<PostProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final attachment = _pickedFile == null
        ? null
        : PostAttachment(
      fileName: _pickedFile!.fileName,
      sizeLabel: _readableSize(_pickedFile!.size),
      fileExtension: _pickedFile!.extension,
    );

    final success = await provider.createPost(
      courseId: widget.courseId,
      content: content,
      attachment: attachment,
    );

    if (!mounted) return;

    if (success) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('تم نشر المنشور بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'تعذر نشر المنشور'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _readableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<PostProvider, bool>((p) => p.isSubmitting);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AcademiaSubAppBar(title: 'إنشاء منشور'),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: isSubmitting,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCourseCard(),
                const SizedBox(height: AppSpacing.medium),
                _buildContentField(),
                const SizedBox(height: AppSpacing.small),
                _buildAttachmentRow(),
                const SizedBox(height: AppSpacing.extraSmall),
                Text(
                  'اكتب منشورًا واضحًا ومفيدًا لزملائك',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: AppSpacing.large),
                ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.small,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                      : Text(
                    'نشر',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard() {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: AppSizes.iconLarge,
            height: AppSizes.iconLarge,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primary,
              size: AppSizes.iconSmall,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'المساق الدراسي',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.courseTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentField() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _contentController,
            textAlign: TextAlign.right,
            maxLines: 6,
            minLines: 4,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'اكتب سؤالك أو ملاحظتك...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDisabled,
              ),
              border: InputBorder.none,
              errorText: _contentError,
              errorStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow() {
    if (_pickedFile == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: _pickAttachment,
          icon: const Icon(Icons.attach_file_rounded, size: 18),
          label: const Text('إضافة مرفق'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
        ),
      );
    }

    return AppCard(
      child: Row(
        children: [
          IconButton(
            onPressed: _removeAttachment,
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _pickedFile!.fileName,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _readableSize(_pickedFile!.size),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: const Icon(
              Icons.insert_drive_file_rounded,
              color: AppColors.warning,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}