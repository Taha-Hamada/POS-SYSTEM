import 'package:flutter/material.dart';

import '../../../core/models/promotion.dart';
import '../../../theme/app_theme.dart';
import '../models/promotion_type_color.dart';

/// شارة نوع العرض بلونه المميّز.
class PromotionTypeBadge extends StatelessWidget {
  const PromotionTypeBadge({super.key, required this.type});

  final PromotionType type;

  @override
  Widget build(BuildContext context) {
    final Color color = type.color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md - 2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(type.icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
