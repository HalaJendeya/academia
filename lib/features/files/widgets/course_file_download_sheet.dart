// lib/features/files/widgets/course_file_download_sheet.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/course_file_model.dart';
import '../services/course_file_download_service.dart';

/// نافذة تنزيل حقيقية: الشريط والنسبة والحجم كلها مبنية من بايتات مستلَمة
/// فعليًا عبر [CourseFileDownloadService]، لا قيم ثابتة.
///
/// لا يوجد "فتح الملف بعد التنزيل" — لا حزمة فتح ملفات مثبَّتة بالمشروع
/// حاليًا (open_file/open_filex)، فتُعرض رسالة نجاح تذكر مسار الحفظ فقط،
/// بدل زر لا يعمل.
class CourseFileDownloadSheet extends StatefulWidget {
  const CourseFileDownloadSheet({super.key, required this.file});

  final CourseFileModel file;

  static Future<void> show(BuildContext context, {required CourseFileModel file}) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) => CourseFileDownloadSheet(file: file),
    );
  }

  @override
  State<CourseFileDownloadSheet> createState() => _CourseFileDownloadSheetState();
}

class _CourseFileDownloadSheetState extends State<CourseFileDownloadSheet> {
  final CourseFileDownloadService _service = CourseFileDownloadService();

  CourseFileDownloadProgress? _progress;
  bool _isCancelled = false;
  bool _isDone = false;
  String? _errorMessage;
  String? _savedPath;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final fileName = widget.file.fileName.trim().isNotEmpty
        ? widget.file.fileName
        : '${widget.file.title}.${widget.file.fileExtension}';

    try {
      final path = await _service.download(
        url: widget.file.cloudinaryUrl,
        fileName: fileName,
        isCancelled: () => _isCancelled,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _isDone = true;
        _savedPath = path;
      });
    } on CourseFileDownloadException catch (e) {
      if (!mounted || _isCancelled) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted || _isCancelled) return;
      setState(() => _errorMessage = AppStrings.fileOpenError);
    }
  }

  void _cancel() {
    setState(() => _isCancelled = true);
    Navigator.of(context).pop();
  }

  String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.small,
        AppSpacing.screenHorizontal,
        AppSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          Text(
            _isDone
                ? AppStrings.downloadCompleteTitle
                : _errorMessage != null
                ? AppStrings.fileDownloadError
                : AppStrings.downloadProgressSheetTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            widget.file.title,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.large),
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            )
          else if (_isDone) ...[
            Text(
              AppStrings.downloadSavedToPrefix + (_savedPath ?? ''),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _progress == null
                      ? ''
                      : _progress!.totalBytes != null
                      ? '${_mb(_progress!.receivedBytes)} / ${_mb(_progress!.totalBytes!)}'
                      : _mb(_progress!.receivedBytes),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
                Text(
                  _progress?.fraction == null
                      ? ''
                      : '${(_progress!.fraction! * 100).round()}% ${AppStrings.downloadProgressCompleteLabel}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: _progress?.fraction,
                minHeight: AppSizes.progressBarHeight,
                backgroundColor: AppColors.surfaceSecondary,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.large),
          if (_isDone || _errorMessage != null)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: Text(
                AppStrings.confirmAction,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
              ),
            )
          else
            OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.border, width: 1),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: const Text(AppStrings.cancelDownloadAction),
            ),
        ],
      ),
    );
  }
}