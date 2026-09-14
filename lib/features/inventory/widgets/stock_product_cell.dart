import 'package:flutter/material.dart';

import '../../../core/widgets/app_data_table.dart';
import '../models/stock_record.dart';
import '../../../theme/app_theme.dart';

/// خلية المنتج: أيقونة الفئة + الاسم والـSKU.
class StockProductCell extends StatelessWidget {
  const StockProductCell({super.key, required this.record});

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
            size: 18,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: TableCells.twoLine(record.productName, record.sku)),
      ],
    );
  }
}
