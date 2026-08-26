// lib/features/files/screens/student_file_preview_screen.dart

import 'package:flutter/material.dart';
import '../services/course_file_opener.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../models/course_file_model.dart';
import '../widgets/student_file_info_card.dart';
import '../widgets/student_file_type_icon.dart';

/// وسيطات شاشة المعاينة.
///
/// الملف يُمرَّر كاملًا لا بمعرّفه: الشاشة السابقة قرأته أصلًا من طرح
/// مصرَّح به، وإعادة قراءته بمعرّفه وحده تحتاج استعلامًا غير مقيَّد بطرح —
/// وهو ما ترفضه القواعد بحق.
class FilePreviewArgs {
  const FilePreviewArgs({required this.file, this.subjectLabel = ''});

  final CourseFileModel file;
  final String subjectLabel;
}

class FilePreviewScreen extends StatelessWidget {
  const FilePreviewScreen({super.key});

  Future<void> _openExternally(
    BuildContext context,
    CourseFileModel file,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // نفس آلية الفتح المستعملة في شاشة ملفات المشرف وتبويب ملفات المساق.
    final result = await openCourseFileUrl(file.cloudinaryUrl);
    if (result == CourseFileOpenResult.opened) return;

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.fileOpenError)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as FilePreviewArgs?;

    if (args == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AcademiaSubAppBar(title: AppStrings.filePreviewTitle),
        body: const Center(child: Text(AppStrings.fileNotFound)),
      );
    }

    final file = args.file;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AcademiaSubAppBar(title: file.title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPreviewArea(file),
              const SizedBox(height: AppSpacing.large),
              _buildOpenAction(context, file),
              const SizedBox(height: AppSpacing.large),
              FileInfoCard(file: file, subjectLabel: args.subjectLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewArea(CourseFileModel file) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Center(child: FileTypeIcon(type: file.typeGroup, size: 72)),
    );
  }

  /// إجراء واحد يعمل فعلًا.
  ///
  /// المشاركة والتنزيل غير المتصل مؤجَّلان، وعرض أزرار لهما يوهم بوظائف
  /// غير موجودة.
  Widget _buildOpenAction(BuildContext context, CourseFileModel file) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _openExternally(context, file),
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.open_in_new_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.extraSmall),
          Text(
            AppStrings.fileOpenExternalAction,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
