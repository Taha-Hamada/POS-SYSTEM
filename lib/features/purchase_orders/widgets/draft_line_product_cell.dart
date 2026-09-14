import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/draft_order_line.dart';

/// خلية المنتج في صف الأمر: الاسم والـSKU والوحدة.
class DraftLineProductCell extends StatelessWidget {
  const DraftLineProductCell({super.key, required this.line});

  final DraftOrderLine line;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
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
                '${line.sku} • ${line.unit}',
                style: AppText.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
