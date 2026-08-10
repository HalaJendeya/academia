// lib/features/files/widgets/student_file_filter_tabs.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Filter row for the All Files screen.
///
/// Three filters ("all", "pdf", "presentations") change
/// [selectedFilter] in place via [onFilterChanged]. The fourth
/// option ("downloaded") is intentionally different: it navigates to
/// a separate Offline Files screen via [onOfflineTap] instead of
/// filtering this screen's list — per product decision.
class FileFilterTabs extends StatelessWidget {
  const FileFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onOfflineTap,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onOfflineTap;

  static const String filterAll = 'all';
  static const String filterPdf = 'pdf';
  static const String filterPresentations = 'presentations';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: [
          _StatusChip(
            label: AppStrings.fileAllFilter,
            isSelected: selectedFilter == filterAll,
            onTap: () => onFilterChanged(filterAll),
          ),
          const SizedBox(width: AppSpacing.small),
          _StatusChip(
            label: AppStrings.fileDownloadedFilter,
            isSelected: false,
            onTap: onOfflineTap,
          ),
          const SizedBox(width: AppSpacing.small),
          _StatusChip(
            label: AppStrings.filePdfFilter,
            isSelected: selectedFilter == filterPdf,
            onTap: () => onFilterChanged(filterPdf),
          ),
          const SizedBox(width: AppSpacing.small),
          _StatusChip(
            label: AppStrings.filePresentationsFilter,
            isSelected: selectedFilter == filterPresentations,
            onTap: () => onFilterChanged(filterPresentations),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}