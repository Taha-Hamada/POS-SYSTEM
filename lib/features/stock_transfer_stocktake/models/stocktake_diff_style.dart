import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import 'stocktake_line.dart';

/// شكل شارة الفرق: أحمر للعجز، أخضر للزيادة، أصفر للمطابقة.
class StocktakeDiffStyle {
  const StocktakeDiffStyle({
    required this.color,
    required this.background,
    required this.label,
    required this.icon,
  });

  /// بيحدد الشكل المناسب لحالة الصف.
  factory StocktakeDiffStyle.of(StocktakeLine line) {
    if (!line.isCounted) {
      return const StocktakeDiffStyle(
        color: AppColors.textMuted,
        background: AppColors.surfaceAlt,
        label: 'لم يُجرد',
        icon: Icons.remove_rounded,
      );
    }

    final double diff = line.difference;
    if (diff < 0) {
      return const StocktakeDiffStyle(
        color: AppColors.danger,
        background: AppColors.dangerSoft,
        label: 'عجز',
        icon: Icons.arrow_downward_rounded,
      );
    }
    if (diff > 0) {
      return const StocktakeDiffStyle(
        color: AppColors.success,
        background: AppColors.successSoft,
        label: 'زيادة',
        icon: Icons.arrow_upward_rounded,
      );
    }
    return const StocktakeDiffStyle(
      color: AppColors.warning,
      background: AppColors.warningSoft,
      label: 'مطابق',
      icon: Icons.check_rounded,
    );
  }

  final Color color;
  final Color background;
  final String label;
  final IconData icon;
}
