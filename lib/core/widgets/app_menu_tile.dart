import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppMenuTile extends StatelessWidget {
  const AppMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconBackgroundColor,
    this.iconColor,
    this.showDivider = true,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final bool showDivider;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.medium,
              horizontal: AppSpacing.cardPadding,
            ),
            child: Row(
              children: [
                // Circular icon container on the right
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        iconBackgroundColor ??
                        AppColors.secondary.withValues(alpha: 0.08),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: iconColor ?? AppColors.secondary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                // Title and subtitle beside it
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: enabled
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Trailing widget on the left
                trailing ??
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: enabled
                          ? AppColors.textSecondary
                          : AppColors.textDisabled,
                      size: 24,
                    ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.divider,
            indent: AppSpacing.huge,
          ),
      ],
    );
  }
}
