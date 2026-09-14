import 'package:flutter/material.dart';


import '../../../theme/app_theme.dart';
import '../../inventory/models/stock_record.dart';

/// خلية المنتج في صف الجرد: أيقونة الفئة + الاسم والـSKU.
class StocktakeProductCell extends StatelessWidget {
  const StocktakeProductCell({super.key, required this.record});

  final StockRecord record;

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
          child: Icon(
            record.categoryIcon,
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
                record.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMedium.copyWith(fontSize: 13),
              ),
              Text(
                record.sku,
                style: AppText.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
