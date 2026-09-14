import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/purchase_order.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/supplier_profile_controller.dart';

/// التبويب التالت: أوامر الشراء الخاصة بالمورد.
class SupplierOrdersTab extends StatelessWidget {
  const SupplierOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final SupplierProfileController profile =
        context.watch<SupplierProfileController>();
    final List<PurchaseOrder> orders = profile.orders;

    return AppDataTable(
      title: 'أوامر الشراء',
      subtitle: '${Fmt.count(orders.length)} أمر توريد',
      minWidth: 880,
      rowHeight: 60,
      emptyMessage: 'لا توجد أوامر شراء لهذا المورد',
      emptyIcon: Icons.shopping_cart_outlined,
      columns: const <AppTableColumn>[
        AppTableColumn('رقم الأمر', size: ColumnSize.S),
        AppTableColumn('التاريخ', size: ColumnSize.M),
        AppTableColumn('الكمية المستلمة', size: ColumnSize.M, numeric: true),
        AppTableColumn('الحالة', size: ColumnSize.M),
        AppTableColumn('الإجمالي', size: ColumnSize.M, numeric: true),
      ],
      rows: <AppTableRow>[
        for (final PurchaseOrder o in orders)
          AppTableRow(
            onTap: () => context.go('/purchases'),
            cells: <Widget>[
              Text(o.number, style: AppText.amountSm.copyWith(fontSize: 13)),
              TableCells.twoLine(
                Fmt.date(o.orderDate),
                o.expectedDate == null
                    ? 'بدون موعد تسليم'
                    : 'التسليم: ${Fmt.date(o.expectedDate!)}',
              ),
              Text(
                '${Fmt.count(o.receivedQuantity.round())} / '
                '${Fmt.count(o.totalQuantity.round())}',
                style: AppText.amountSm,
              ),
              StatusBadge(label: o.status.label, tone: o.status.tone),
              TableCells.amount(o.total),
            ],
          ),
      ],
      footer: Row(
        children: <Widget>[
          Text('إجمالي قيمة الأوامر', style: AppText.caption),
          const Spacer(),
          Text(Fmt.money(profile.ordersTotal), style: AppText.amountMd),
        ],
      ),
    );
  }
}
