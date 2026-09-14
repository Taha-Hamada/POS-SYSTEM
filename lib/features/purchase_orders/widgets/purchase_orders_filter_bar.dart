import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/purchase_orders_controller.dart';
import 'purchase_orders_status_dropdown.dart';
import 'purchase_orders_supplier_dropdown.dart';

/// شريط فوق الجدول: عنوان القسم، العدّاد، البحث، وفلاتر المورد والحالة.
class PurchaseOrdersFilterBar extends StatelessWidget {
  const PurchaseOrdersFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final PurchaseOrdersController orders =
        context.watch<PurchaseOrdersController>();

    return Row(
      children: <Widget>[
        Text('سجل الأوامر', style: AppText.sectionTitle),
        const SizedBox(width: AppSpacing.md),
        Text('(${Fmt.count(orders.visibleCount)})', style: AppText.caption),
        const Spacer(),
        SearchField(
          controller: orders.searchController,
          hint: 'ابحث برقم الأمر…',
          onChanged: orders.setQuery,
        ),
        const SizedBox(width: AppSpacing.md),
        const PurchaseOrdersSupplierDropdown(),
        const SizedBox(width: AppSpacing.md),
        const PurchaseOrdersStatusDropdown(),
      ],
    );
  }
}
