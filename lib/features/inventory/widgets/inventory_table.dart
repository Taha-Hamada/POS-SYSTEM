import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/api/api_client.dart';
import '../data/inventory_repository.dart';
import '../models/stock_record.dart';
import 'stock_movements_dialog.dart';
import '../../../theme/app_theme.dart';
import '../controllers/inventory_controller.dart';
import 'inventory_table_footer.dart';
import 'stock_branch_cell.dart';
import 'stock_last_movement_cell.dart';
import 'stock_product_cell.dart';

/// جدول أرصدة المخزون.
class InventoryTable extends StatelessWidget {
  const InventoryTable({super.key});

  static const List<AppTableColumn> _columns = <AppTableColumn>[
    AppTableColumn('المنتج', size: ColumnSize.L, sortable: true),
    AppTableColumn('الفرع / المخزن', size: ColumnSize.M, sortable: true),
    AppTableColumn(
      'الكمية الفعلية',
      size: ColumnSize.S,
      sortable: true,
      numeric: true,
      tooltip: 'الرصيد الموجود فعليًا على الرف',
    ),
    AppTableColumn('الحالة', size: ColumnSize.M),
    AppTableColumn('آخر حركة', size: ColumnSize.M, sortable: true),
  ];

  List<Widget> _cells(StockRecord r) {
    return <Widget>[
      StockProductCell(record: r),
      StockBranchCell(name: r.branchName),
      TableCells.count(r.onHand),
      // الحالة على الرصيد الفعلي وحد الطلب المحسوب على السيرفر.
      StatusBadge.stock(stock: r.onHand, minStock: r.minStock, compact: true),
      StockLastMovementCell(date: r.lastMovement),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final InventoryController inventory = context.watch<InventoryController>();

    return AppDataTable(
      minWidth: 1120,
      rowHeight: 62,
      sortColumnIndex: inventory.sortIndex,
      sortAscending: inventory.sortAscending,
      onSort: inventory.sortBy,
      emptyMessage: 'لا توجد أرصدة مسجّلة لهذا الفرع',
      emptyIcon: Icons.warehouse_outlined,
      columns: _columns,
      rows: <AppTableRow>[
        for (final StockRecord r in inventory.rows)
          AppTableRow(
            highlightColor: r.onHand <= 0
                ? AppColors.dangerSoft.withValues(alpha: 0.5)
                : null,
            onTap: () => showStockMovementsDialog(
              context,
              repository: InventoryRepository(context.read<ApiClient>()),
              record: r,
            ),
            cells: _cells(r),
          ),
      ],
      footer: const InventoryTableFooter(),
    );
  }
}
