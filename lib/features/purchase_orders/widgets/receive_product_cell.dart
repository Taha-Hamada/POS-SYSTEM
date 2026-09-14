import 'package:flutter/material.dart';

import '../../../core/models/purchase_order.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// خلية المنتج في صف الاستلام: الاسم والـSKU وسعر الشراء.
class ReceiveProductCell extends StatelessWidget {
  const ReceiveProductCell({super.key, required this.line});

  final PurchaseOrderLine line;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: AppRadius.smAll,
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            size: 17,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                line.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMedium.copyWith(fontSize: 13),
              ),
              Text(
                '${line.sku} • ${Fmt.money(line.unitCost)}',
                style: AppText.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
