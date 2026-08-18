
// lib/features/files/widgets/student_file_type_icon.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../models/course_file_model.dart';

/// Colored, rounded icon representing a file's type
/// (PDF, DOC, PPT, image, or other).
///
/// Shared across the Files feature's cards (list item, file info
/// card) to avoid duplicating the type→color/icon mapping.
class FileTypeIcon extends StatelessWidget {
  const FileTypeIcon({super.key, required this.type, this.size = 48});

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(type);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Icon(config.icon, color: config.color, size: size * 0.55),
    );
  }

  _FileTypeConfig _configFor(String type) {
    switch (type) {
      case CourseFileModel.typePdf:
        return const _FileTypeConfig(
          icon: Icons.picture_as_pdf_rounded,
          color: AppColors.error,
        );
      case CourseFileModel.typeDoc:
        return const _FileTypeConfig(
          icon: Icons.description_rounded,
          color: AppColors.secondary,
        );
      case CourseFileModel.typePpt:
        return const _FileTypeConfig(
          icon: Icons.slideshow_rounded,
          color: AppColors.primary,
        );
      case CourseFileModel.typeImage:
        return const _FileTypeConfig(
          icon: Icons.image_rounded,
          color: AppColors.secondary,
        );
      default:
        return const _FileTypeConfig(
          icon: Icons.insert_drive_file_rounded,
          color: AppColors.textMuted,
        );
    }
  }
}

class _FileTypeConfig {
  const _FileTypeConfig({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}