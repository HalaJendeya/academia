import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppDestructiveButton extends StatelessWidget {
  const AppDestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.fullWidth = true,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;
  final bool fullWidth;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final textColor = filled ? Colors.white : AppColors.danger;
    final iconColor = filled ? Colors.white : AppColors.danger;

    final buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: textColor,
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: AppSpacing.small),
          ],
          Text(
            label,
            style: AppTextStyles.primaryButton.copyWith(color: textColor),
          ),
        ],
      ],
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: filled
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.danger.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                elevation: 0,
              ),
              onPressed: (isEnabled && !isLoading) ? onPressed : null,
              child: buttonContent,
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                elevation: 0,
              ),
              onPressed: (isEnabled && !isLoading) ? onPressed : null,
              child: buttonContent,
            ),
    );
  }
}
