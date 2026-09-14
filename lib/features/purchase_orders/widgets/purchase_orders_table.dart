import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/purchase_order.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/purchase_orders_controller.dart';
import '../screens/receive_goods_dialog.dart';
import 'cancel_order_dialog.dart';
import 'purchase_order_row_action.dart';
import 'purchase_order_supplier_cell.dart';
import 'purchase_orders_table_footer.dart';
import 'receive_progress_cell.dart';

/// جدول أوامر الشراء.
class PurchaseOrdersTable extends StatelessWidget {
  const PurchaseOrdersTable({super.key});

  /// عمود المورد بيتفرز محليًا لأن السيرفر بيفرز بمعرّف المورد مش باسمه.
  static const List<AppTableColumn> _columns = <AppTableColumn>[
    AppTableColumn('رقم الأمر', size: ColumnSize.S, sortable: true),
    AppTableColumn('المورد', size: ColumnSize.L, sortable: true),
    AppTableColumn('التاريخ', size: ColumnSize.M, sortable: true),
    AppTableColumn('الحالة', size: ColumnSize.M, sortable: true),
    AppTableColumn('نسبة الاستلام', size: ColumnSize.M),
    AppTableColumn(
      'الإجمالي',
      size: ColumnSize.M,
      sortable: true,
      numeric: true,
    ),
    AppTableColumn('', fixedWidth: 190),
  ];

  /// المسودة بتتأكد، والمؤكد بيتستلم — كل حالة وإجراؤها.
  Future<void> _primaryAction(BuildContext context, PurchaseOrder order) async {
    final PurchaseOrdersController orders =
        context.read<PurchaseOrdersController>();

    if (order.isDraft) {
      final String? error = await orders.confirm(order);
      if (!context.mounted) return;

      showPlainSnackBar(
        context,
        error ?? 'اتأكد الأمر ${order.number} وبقى جاهز للاستلام',
        width: 460,
      );
      return;
    }

    if (!order.canReceive) {
      showPlainSnackBar(
        context,
        order.isCancelled
            ? 'الأمر ${order.number} ملغي'
            : 'الأمر ${order.number} مستلم بالكامل',
        width: 460,
      );
      return;
    }

    // القايمة بترجع من غير سطور، والاستلام محتاجها.
    final PurchaseOrder? full = await orders.fetchFullOrder(order.id);
    if (full == null || !context.mounted) return;

    final PurchaseOrder? received = await showReceiveGoodsDialog(context, full);
    if (received == null || !context.mounted) return;

    await orders.refreshAfterReceipt();
    if (!context.mounted) return;

    showPlainSnackBar(
      context,
      received.isCompleted
          ? 'اتستلم الأمر ${received.number} بالكامل'
          : 'اتسجل استلام جزئي للأمر ${received.number}',
      width: 460,
    );
  }

  Future<void> _cancel(BuildContext context, PurchaseOrder order) async {
    final PurchaseOrdersController orders =
        context.read<PurchaseOrdersController>();

    // السيرفر بيرفض الإلغاء من غير سبب.
    final String? reason = await showCancelOrderDialog(context, order);
    if (reason == null || !context.mounted) return;

    final String? error = await orders.cancel(order, reason: reason);
    if (!context.mounted) return;

    showPlainSnackBar(
      context,
      error ?? 'اتلغى الأمر ${order.number}',
      width: 460,
    );
  }

  List<Widget> _cells(BuildContext context, PurchaseOrder o, bool hovered) {
    return <Widget>[
      Text(o.number, style: AppText.amountSm.copyWith(fontSize: 13.5)),
      PurchaseOrderSupplierCell(order: o),
      TableCells.twoLine(
        Fmt.date(o.orderDate),
        o.expectedDate == null
            ? 'بدون موعد تسليم'
            : 'التسليم: ${Fmt.date(o.expectedDate!)}',
      ),
      StatusBadge(label: o.status.label, tone: o.status.tone),
      ReceiveProgressCell(ratio: o.receivedRatio),
      Text(Fmt.money(o.total), style: AppText.amountSm),
      PurchaseOrderRowAction(
        order: o,
        hovered: hovered,
        onPressed: () => _primaryAction(context, o),
        onCancel: () => _cancel(context, o),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final PurchaseOrdersController orders =
        context.watch<PurchaseOrdersController>();

    if (orders.isFirstLoad) {
      return const LoadingView(message: 'بنجيب أوامر الشراء…');
    }

    if (orders.hasFailed) {
      return ErrorView(message: orders.errorMessage!, onRetry: orders.retry);
    }

    return AppDataTable(
      minWidth: 1150,
      rowHeight: 66,
      sortColumnIndex: orders.sortIndex,
      sortAscending: orders.sortAscending,
      onSort: orders.sortBy,
      emptyMessage: 'لا توجد أوامر شراء مطابقة',
      emptyIcon: Icons.shopping_cart_outlined,
      columns: _columns,
      rows: <AppTableRow>[
        for (final PurchaseOrder o in orders.rows)
          AppTableRow(
            onTap: () => _primaryAction(context, o),
            cellsBuilder: (bool hovered) => _cells(context, o, hovered),
          ),
      ],
      footer: const PurchaseOrdersTableFooter(),
    );
  }
}
