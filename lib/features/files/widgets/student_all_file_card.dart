// lib/features/files/widgets/student_all_file_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/student_app_file.dart';
import '../providers/student_file_provider.dart';
import 'student_file_type_icon.dart';

class AllFileCard extends StatelessWidget {
  const AllFileCard({
    super.key,
    required this.file,
    this.onTap,
    this.onDownloadTap,
    this.onDeleteTap,
  });

  final StudentAppFile file;
  final VoidCallback? onTap;
  final VoidCallback? onDownloadTap;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FileTypeIcon(type: file.type),
          const SizedBox(width: AppSpacing.medium),
          Expanded(child: _buildInfo()),
          const SizedBox(width: AppSpacing.small),
          if (!file.isDownloaded) ...[
            IconButton(
              onPressed: onDownloadTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.download_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
          ],
          _buildBadgeAndMenuColumn(context),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                file.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
                softWrap: true,
              ),
            ),
            if (file.isNew) ...[const SizedBox(width: 6), _buildNewBadge()],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${file.subjectLabel} • ${file.sizeLabel}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildBadgeAndMenuColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (file.isDownloaded) ...[
          _buildOfflineBadge(),
          const SizedBox(height: AppSpacing.small),
        ],
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.more_vert_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          onSelected: (value) {
            if (value == 'delete') onDeleteTap?.call();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.deleteFileAction,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOfflineBadge() {
    return Consumer<StudentFileProvider>(
      builder: (context, provider, _) {
        final isOnline = provider.isOnline;
        final color = isOnline ? AppColors.success : AppColors.secondary;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Text(
            AppStrings.offlineFileBadgeLabel,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        AppStrings.newFileBadgeLabel,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}