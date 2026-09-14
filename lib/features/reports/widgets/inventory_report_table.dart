import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/reports_controller.dart';
import '../models/report_rows.dart';
import 'bar_cell.dart';
import 'report_footer_totals.dart';
import 'report_icon_cell.dart';

/// جدول قيمة المخزون حسب الفئة.
class InventoryReportTable extends StatelessWidget {
  const InventoryReportTable({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportsController reports = context.watch<ReportsController>();
    final List<InventoryReportRow> rows = reports.inventoryRows;

    final double totalCost = reports.inventoryTotalCost;
    final double totalRetail = reports.inventoryTotalRetail;
    final double maxCost = rows.isEmpty ? 1 : rows.first.cost;

    return AppDataTable(
      title: 'قيمة المخزون حسب الفئة',
      subtitle: 'مرتّبة حسب قيمة التكلفة',
      minWidth: 900,
      rowHeight: 58,
      columns: const <AppTableColumn>[
        AppTableColumn('الفئة', size: ColumnSize.L),
        AppTableColumn('الأصناف', size: ColumnSize.S, numeric: true),
        AppTableColumn('الوحدات', size: ColumnSize.S, numeric: true),
        AppTableColumn('قيمة التكلفة', size: ColumnSize.M, numeric: true),
        AppTableColumn('قيمة البيع', size: ColumnSize.M, numeric: true),
        AppTableColumn('الربح المتوقع', size: ColumnSize.M, numeric: true),
      ],
      rows: <AppTableRow>[
        for (final InventoryReportRow r in rows)
          AppTableRow(
            cells: <Widget>[
              ReportIconCell(
                icon: r.icon,
                title: r.name,
              ),
              TableCells.count(r.items),
              TableCells.count(r.units.round()),
              BarCell(value: r.cost, max: maxCost),
              TableCells.amount(r.retail, color: AppColors.textSecondary),
              TableCells.amount(
                r.expectedProfit,
                color: AppColors.success,
              ),
            ],
          ),
      ],
      footer: ReportFooterTotals(
        totals: <(String, String)>[
          ('التكلفة', Fmt.money(totalCost)),
          ('البيع', Fmt.money(totalRetail)),
          ('الربح', Fmt.money(totalRetail - totalCost)),
        ],
      ),
    );
  }
}
