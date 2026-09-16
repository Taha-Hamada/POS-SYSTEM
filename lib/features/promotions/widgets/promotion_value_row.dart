import 'package:flutter/material.dart';

import '../../../core/models/promotion.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../models/promotion_type_color.dart';

/// قيمة العرض + عدد الفواتير اللي اتطبق فيها.
class PromotionValueRow extends StatelessWidget {
  const PromotionValueRow({super.key, required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              promotion.valueLabel,
              style: AppText.amountHero.copyWith(
                fontSize: 26,
                color: promotion.type.color,
              ),
            ),
          ),
        ),
        const Spacer(),
        if (promotion.usageCount > 0)
          Row(
            children: <Widget>[
              const Icon(
                Icons.shopping_bag_outlined,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '${Fmt.count(promotion.usageCount)} فاتورة',
                style: AppText.caption.copyWith(fontSize: 11.5),
              ),
            ],
          ),
      ],
    );
  }
}
