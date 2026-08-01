import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.child,
    this.title,
    this.action,
    this.spacing,
  });

  final Widget child;
  final String? title;
  final Widget? action;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null || action != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (title != null)
                Text(title!, style: AppTextStyles.sectionTitle),
              ?action,
            ],
          ),
          SizedBox(height: spacing ?? AppSpacing.itemSpacing),
        ],
        child,
      ],
    );
  }
}
