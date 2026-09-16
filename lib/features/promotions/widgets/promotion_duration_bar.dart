import 'package:flutter/material.dart';

import '../../../core/models/promotion.dart';
import '../../../theme/app_theme.dart';
import '../models/promotion_type_color.dart';

/// شريط نسبة المدة المنقضية من العرض.
class PromotionDurationBar extends StatelessWidget {
  const PromotionDurationBar({super.key, required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final bool live = promotion.status == PromotionStatus.active;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: 5,
        child: Stack(
          children: <Widget>[
            Container(color: AppColors.surfaceAlt),
            FractionallySizedBox(
              widthFactor: promotion.elapsedRatio,
              child: Container(
                color: live
                    ? promotion.type.color.withValues(alpha: 0.7)
                    : AppColors.borderStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
