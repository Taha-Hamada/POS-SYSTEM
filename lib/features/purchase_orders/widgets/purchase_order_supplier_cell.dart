import 'package:flutter/material.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../core/models/purchase_order.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// خلية المورد: أيقونة + الاسم وتحته عدد الأصناف والوحدات.
class PurchaseOrderSupplierCell extends StatelessWidget {
  const PurchaseOrderSupplierCell({super.key, required this.order});

  final PurchaseOrder order;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.10),
            borderRadius: AppRadius.smAll,
          ),
          child: const Icon(
            Icons.storefront_rounded,
            size: 17,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          // القايمة بترجع من غير السطور، فبنعرض الوحدات اللي السيرفر بيحسبها.
          child: TableCells.twoLine(
            order.supplierName,
            '${Fmt.count(order.totalQuantity.round())} وحدة مطلوبة',
          ),
        ),
      ],
    );
  }
}
