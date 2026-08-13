// lib/features/files/screens/course_file_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../models/course_file_model.dart';
import '../widgets/course_file_download_sheet.dart';

/// معاينة ملف مساق واحد، تُفتح من تبويب "ملفات المساق" أو شاشة "كل
/// الملفات". يستقبل [CourseFileModel] كاملًا كوسيط بدل معرّف — الشاشة التي
/// تفتحه أصلًا حمّلت قائمة الملفات بالفعل، فلا داعي لاستعلام إضافي.
///
/// "مشاركة" معطّلة عمدًا بحالة "قيد التطوير": لا حزمة مشاركة (share_plus)
/// مثبَّتة بالمشروع، وتزييف السلوك أسوأ من تعطيل صريح.
class CourseFilePreviewScreen extends StatelessWidget {
  const CourseFilePreviewScreen({super.key, required this.file});

  final CourseFileModel file;

  static Route<void> route(CourseFileModel file) {
    return MaterialPageRoute(
      builder: (_) => CourseFilePreviewScreen(file: file),
    );
  }

  Future<void> _openExternal(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(file.cloudinaryUrl);
    if (uri == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.fileOpenError)),
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.fileOpenError)),
      );
    }
  }

  Future<void> _shareFile(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (file.cloudinaryUrl.trim().isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.fileOpenError)),
      );
      return;
    }
    await Share.share(file.cloudinaryUrl, subject: file.title);
  }

  void _startDownload(BuildContext context) {
    CourseFileDownloadSheet.show(context, file: file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AcademiaSubAppBar(title: file.title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPreviewArea(),
              const SizedBox(height: AppSpacing.large),
              _buildActionButtons(context),
              const SizedBox(height: AppSpacing.large),
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Center(
        child: _PreviewFileIcon(extension: file.fileExtension),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(
          icon: Icons.open_in_new_rounded,
          label: AppStrings.fileOpenExternalAction,
          onTap: () => _openExternal(context),
        ),
        _actionButton(
          icon: Icons.share_rounded,
          label: AppStrings.fileShareAction,
          onTap: () => _shareFile(context),
        ),
        _actionButton(
          icon: Icons.download_rounded,
          label: AppStrings.fileDownloadAction,
          onTap: () => _startDownload(context),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.extraSmall),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.fileInfoSectionTitle,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: AppSpacing.medium),
          _infoRow(
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.primary,
            label: AppStrings.fileInfoSubjectLabel,
            value: AppStrings.fileCategoryDisplay(file.category),
          ),
          const SizedBox(height: AppSpacing.medium),
          _infoRow(
            icon: Icons.folder_zip_rounded,
            iconColor: AppColors.primaryDark,
            label: AppStrings.fileInfoSizeLabel,
            value: file.readableSize,
          ),
          const SizedBox(height: AppSpacing.medium),
          _infoRow(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.primary,
            label: AppStrings.fileInfoDateLabel,
            value: _formatDate(file.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: AppSizes.iconLarge,
          height: AppSizes.iconLarge,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(icon, color: iconColor, size: AppSizes.iconSmall),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 2),
              Text(
                value,
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
    );
  }

  static const List<String> _arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day} ${_arabicMonths[date.month - 1]} ${date.year}';
  }
}

class _PreviewFileIcon extends StatelessWidget {
  const _PreviewFileIcon({required this.extension});

  final String extension;

  @override
  Widget build(BuildContext context) {
    final ext = extension.toLowerCase();
    IconData icon = Icons.insert_drive_file_rounded;
    Color color = AppColors.secondary;
    if (ext == 'pdf') {
      icon = Icons.picture_as_pdf_rounded;
      color = AppColors.warning;
    } else if (ext == 'ppt' || ext == 'pptx') {
      icon = Icons.slideshow_rounded;
      color = AppColors.warning;
    } else if (ext == 'doc' || ext == 'docx') {
      icon = Icons.description_rounded;
    } else if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      icon = Icons.image_rounded;
    }
    return Icon(icon, color: color, size: 72);
  }
}