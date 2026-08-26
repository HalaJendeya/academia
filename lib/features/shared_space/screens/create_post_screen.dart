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
import '../../files/services/cloudinary_upload_service.dart';
import '../../files/services/course_file_picker.dart';
import '../models/post_attachment.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';

/// إنشاء منشور جديد، أو تعديل منشور موجود — نفس الشاشة بوضعين، لا شاشتين
/// منفصلتين تتكرر فيهما كل الحقول والتحقق.
///
/// [existingPost] فارغ = إنشاء (السلوك الأصلي دون تغيير). ممرَّر = تعديل:
/// الحقول تُعبَّأ بمحتواه الحالي، العنوان وزر الحفظ يتغيّران، والإرسال
/// يستدعي [PostProvider.updatePost] بدل [PostProvider.createPost]. مساق
/// المنشور غير قابل للتغيير أثناء التعديل — منشور لا "ينتقل" بين مساقات.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.existingPost,
  });

  final String courseId;
  final String courseTitle;
  final PostModel? existingPost;

  bool get isEditing => existingPost != null;

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

  static Route<void> editRoute({required PostModel post, required String courseTitle}) {
    return MaterialPageRoute(
      builder: (_) => CreatePostScreen(
        courseId: post.courseId,
        courseTitle: courseTitle,
        existingPost: post,
      ),
    );
  }

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final CloudinaryUploadService _uploadService = CloudinaryUploadService();

  PickedCourseFile? _pickedFile;

  /// مرفق المنشور الأصلي وقت فتح شاشة التعديل — يبقى كما هو ما لم يستبدله
  /// المستخدم صراحةً بملف جديد أو يزيله. غير موجود بوضع الإنشاء.
  PostAttachment? _existingAttachment;

  String? _contentError;
  String? _uploadError;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPost;
    if (existing != null) {
      _contentController.text = existing.content;
      _existingAttachment = existing.attachment;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _uploadService.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final picked = await pickCourseFile();
    if (picked == null || !mounted) return;
    setState(() {
      _pickedFile = picked;
      _uploadError = null;
    });
  }

  void _removeAttachment() {
    setState(() {
      _pickedFile = null;
      _existingAttachment = null;
      _uploadError = null;
    });
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _contentError = 'يرجى كتابة نص المنشور');
      return;
    }
    setState(() {
      _contentError = null;
      _uploadError = null;
    });

    final provider = context.read<PostProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // اسم الكاتب الحقيقي من بروفايل الطالب — يُقرأ الآن قبل أي await، لا
    // بعد رفع مرفق قد يأخذ ثوانٍ (تجنّب context بعد فجوة غير متزامنة).
    // غير مطلوب فعليًا بوضع التعديل (لا يُعاد إرسال authorName)، لكن
    // التحقق يبقى موحَّدًا في الحالتين — رسالة خطأ واحدة، لا مسارين.
    // لا فحص هوية هنا: الاسم يُقرأ في الخدمة من مستند المستخدم العام،
    // والمعرّف من مستخدم المصادقة. انظر PostService._requireAuthorName.

    // 1) رفع ملف جديد فقط إن اختار المستخدم واحدًا فعليًا. المرفق الأصلي
    // (بوضع التعديل) يبقى كما هو دون أي رفع جديد إن لم يُغيَّر.
    PostAttachment? attachment = _existingAttachment;
    if (_pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final result = await _uploadService.uploadPostAttachment(
          bytes: _pickedFile!.bytes,
          fileName: _pickedFile!.fileName,
          courseId: widget.courseId,
        );
        attachment = PostAttachment(
          fileName: _pickedFile!.fileName,
          fileUrl: result.secureUrl,
          sizeLabel: _readableSize(result.bytes),
          fileExtension: result.format,
        );
      } on CloudinaryUploadException catch (e) {
        if (!mounted) return;
        setState(() {
          _isUploading = false;
          _uploadError = e.message;
        });
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isUploading = false;
          _uploadError = 'تعذر رفع المرفق، حاول مرة أخرى.';
        });
        return;
      }
      if (!mounted) return;
      setState(() => _isUploading = false);
    }

    // 2) إنشاء أو تعديل، حسب الوضع.
    final existingPost = widget.existingPost;
    final success = existingPost == null
        ? await provider.createPost(
      courseId: widget.courseId,
      content: content,
      attachment: attachment,
    )
        : await provider.updatePost(
      postId: existingPost.id,
      content: content,
      attachment: attachment,
    );

    if (!mounted) return;

    if (success) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(existingPost == null ? 'تم نشر المنشور بنجاح' : 'تم حفظ التعديلات'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                (existingPost == null ? 'تعذر نشر المنشور' : 'تعذر حفظ التعديلات'),
          ),
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
    final isBusy = isSubmitting || _isUploading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AcademiaSubAppBar(title: widget.isEditing ? 'تعديل المنشور' : 'إنشاء منشور'),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: isBusy,
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
                if (_uploadError != null) ...[
                  const SizedBox(height: AppSpacing.extraSmall),
                  Text(
                    _uploadError!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                    textAlign: TextAlign.right,
                  ),
                ],
                const SizedBox(height: AppSpacing.extraSmall),
                Text(
                  'اكتب منشورًا واضحًا ومفيدًا لزملائك',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: AppSpacing.large),
                ElevatedButton(
                  onPressed: isBusy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: isBusy
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                      : Text(
                    widget.isEditing ? 'حفظ التعديلات' : 'نشر',
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
            child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: AppSizes.iconSmall),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'المساق الدراسي',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
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
      child: TextField(
        controller: _contentController,
        textAlign: TextAlign.right,
        maxLines: 6,
        minLines: 4,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'اكتب سؤالك أو ملاحظتك...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
          border: InputBorder.none,
          errorText: _contentError,
          errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildAttachmentRow() {
    // لا مرفق إطلاقًا (لا قديم ولا جديد) — زر الإضافة فقط.
    if (_pickedFile == null && _existingAttachment == null) {
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

    // اسم وحجم العرض — من الملف المحلي المختار حديثًا إن وُجد، وإلا من
    // المرفق الأصلي بوضع التعديل. لا يُعرضان معًا: أحدهما دومًا null.
    final displayName = _pickedFile?.fileName ?? _existingAttachment!.fileName;
    final displaySize = _pickedFile != null
        ? _readableSize(_pickedFile!.size)
        : _existingAttachment!.sizeLabel;

    return AppCard(
      child: Row(
        children: [
          if (_isUploading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          else
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
                  displayName,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  displaySize,
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
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
            child: const Icon(Icons.insert_drive_file_rounded, color: AppColors.warning, size: 18),
          ),
        ],
      ),
    );
  }
}