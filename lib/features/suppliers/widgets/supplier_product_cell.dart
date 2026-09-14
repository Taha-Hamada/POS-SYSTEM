import 'package:flutter/material.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../theme/app_theme.dart';
import '../models/supplied_product.dart';

/// خلية الصنف في جدول الأصناف الموردة.
class SupplierProductCell extends StatelessWidget {
  const SupplierProductCell({super.key, required this.product});

  final SuppliedProduct product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: product.accentColor.withValues(alpha: 0.12),
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(
            product.categoryIcon,
            size: 17,
            color: product.accentColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: TableCells.primary(product.name)),
      ],
    );
  }
}
