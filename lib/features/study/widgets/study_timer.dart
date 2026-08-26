import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// عرض العدّ التنازلي.
///
/// عرض بحت بلا منطق: [remaining] و[total] يصلان محسوبين من
/// [StudySessionProvider]، فلا يحتفظ هذا العنصر بحالة زمنية خاصة قد
/// تختلف عمّا يخزّنه المزوّد.
class StudyTimer extends StatelessWidget {
  const StudyTimer({
    super.key,
    required this.remaining,
    required this.total,
    this.isPaused = false,
    this.size = 220,
  });

  final Duration remaining;
  final Duration total;
  final bool isPaused;
  final double size;

  /// mm:ss بأرقام لاتينية، وهي ما تعرضه ساعات الأجهزة في الواجهة العربية.
  static String format(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final minutes = safe.inMinutes.toString().padLeft(2, '0');
    final seconds = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress {
    if (total.inSeconds <= 0) return 0;
    final done = total.inSeconds - remaining.inSeconds;
    final value = done / total.inSeconds;
    if (value.isNaN) return 0;
    return value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 10,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaused ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                format(remaining),
                style: AppTextStyles.displayMedium,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
