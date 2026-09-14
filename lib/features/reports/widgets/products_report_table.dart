import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../theme/app_theme.dart';
import '../../dashboard/models/dashboard_data.dart';
import '../controllers/reports_controller.dart';
import '../models/report_period.dart';
import 'bar_cell.dart';
import 'report_icon_cell.dart';

/// جدول أداء المنتجات.
///
/// التقرير بيرجّع أرقام مبيعات مش سجل المنتج، فمفيش عمود للرصيد أو الحالة —
/// دول في شاشة المخزون.
class ProductsReportTable extends StatelessWidget {
  const ProductsReportTable({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportsController reports = context.watch<ReportsController>();
    final List<TopProduct> stats = reports.topProducts;
    final double maxRevenue = stats.isEmpty ? 1 : stats.first.revenue;

    return AppDataTable(
      title: 'أداء المنتجات',
      subtitle: 'أعلى 20 صنفًا خلال ${reports.period.label}',
      minWidth: 860,
      rowHeight: 58,
      emptyMessage: 'مفيش مبيعات في الفترة دي',
      emptyIcon: Icons.inventory_2_outlined,
      columns: const <AppTableColumn>[
        AppTableColumn('المنتج', size: ColumnSize.L),
        AppTableColumn('الوحدات', size: ColumnSize.S, numeric: true),
        AppTableColumn('الإيراد', size: ColumnSize.M, numeric: true),
        AppTableColumn('الربح', size: ColumnSize.M, numeric: true),
        AppTableColumn('الهامش', size: ColumnSize.S, numeric: true),
      ],
      rows: <AppTableRow>[
        for (int i = 0; i < stats.length; i += 1)
          AppTableRow(
            cells: <Widget>[
              ReportIconCell(
                icon: Icons.inventory_2_outlined,
                title: stats[i].name,
                subtitle: stats[i].sku,
                color: AppColors
                    .productPalette[i % AppColors.productPalette.length],
              ),
              TableCells.count(stats[i].units.round()),
              BarCell(
                value: stats[i].revenue,
                max: maxRevenue,
                color: AppColors
                    .productPalette[i % AppColors.productPalette.length],
              ),
              TableCells.amount(stats[i].profit, color: AppColors.success),
              TableCells.secondary(
                stats[i].revenue == 0
                    ? '—'
                    : '${(stats[i].profit / stats[i].revenue * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
      ],
    );
  }
}
