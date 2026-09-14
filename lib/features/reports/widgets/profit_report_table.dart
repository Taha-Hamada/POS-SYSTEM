import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/reports_controller.dart';
import '../models/report_rows.dart';
import 'bar_cell.dart';
import 'margin_cell.dart';
import 'report_footer_totals.dart';
import 'report_icon_cell.dart';

/// جدول الربحية حسب الفئة.
class ProfitReportTable extends StatelessWidget {
  const ProfitReportTable({super.key});

  @override
  Widget build(BuildContext context) {
    final List<CategoryReportRow> rows =
        context.watch<ReportsController>().categoryRows;

    final double revenue =
        rows.fold<double>(0, (double s, CategoryReportRow r) => s + r.revenue);
    final double cost =
        rows.fold<double>(0, (double s, CategoryReportRow r) => s + r.cost);
    final double maxRevenue = rows.isEmpty ? 1 : rows.first.revenue;

    return AppDataTable(
      title: 'الربحية حسب الفئة',
      subtitle: 'مرتّبة تنازليًا حسب الإيراد',
      minWidth: 900,
      rowHeight: 58,
      columns: const <AppTableColumn>[
        AppTableColumn('الفئة', size: ColumnSize.L),
        AppTableColumn('الوحدات', size: ColumnSize.S, numeric: true),
        AppTableColumn('الإيراد', size: ColumnSize.M, numeric: true),
        AppTableColumn('التكلفة', size: ColumnSize.M, numeric: true),
        AppTableColumn('الربح', size: ColumnSize.M, numeric: true),
        AppTableColumn('الهامش', size: ColumnSize.M),
      ],
      rows: <AppTableRow>[
        for (final CategoryReportRow r in rows)
          AppTableRow(
            cells: <Widget>[
              ReportIconCell(
                icon: r.icon,
                title: r.name,
                subtitle: '${r.share.toStringAsFixed(1)}% من المبيعات',
              ),
              TableCells.count(r.units.round()),
              BarCell(value: r.revenue, max: maxRevenue),
              TableCells.amount(r.cost, color: AppColors.textSecondary),
              TableCells.amount(r.profit, color: AppColors.success),
              MarginCell(margin: r.margin),
            ],
          ),
      ],
      footer: ReportFooterTotals(
        totals: <(String, String)>[
          ('الإيراد', Fmt.money(revenue)),
          ('التكلفة', Fmt.money(cost)),
          ('الربح', Fmt.money(revenue - cost)),
        ],
      ),
    );
  }
}
