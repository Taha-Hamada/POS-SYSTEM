import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../dashboard/models/dashboard_data.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/reports_controller.dart';
import 'report_footer_totals.dart';

/// جدول التفاصيل اليومية في تقرير المبيعات.
class SalesReportTable extends StatelessWidget {
  const SalesReportTable({super.key});

  /// اسم اليوم بالعربي تحت التاريخ.
  String _weekdayName(DateTime d) => switch (d.weekday) {
        DateTime.saturday => 'السبت',
        DateTime.sunday => 'الأحد',
        DateTime.monday => 'الاثنين',
        DateTime.tuesday => 'الثلاثاء',
        DateTime.wednesday => 'الأربعاء',
        DateTime.thursday => 'الخميس',
        _ => 'الجمعة',
      };

  @override
  Widget build(BuildContext context) {
    final ReportsController reports = context.watch<ReportsController>();
    final List<SalesPoint> series = reports.series;

    return AppDataTable(
      title: 'التفاصيل اليومية',
      subtitle: '${Fmt.count(series.length)} يوم',
      minWidth: 760,
      rowHeight: 54,
      columns: const <AppTableColumn>[
        AppTableColumn('التاريخ', size: ColumnSize.M),
        AppTableColumn('الفواتير', size: ColumnSize.S, numeric: true),
        AppTableColumn('المبيعات', size: ColumnSize.M, numeric: true),
        AppTableColumn('الضريبة', size: ColumnSize.S, numeric: true),
        AppTableColumn('صافي الربح', size: ColumnSize.M, numeric: true),
      ],
      rows: <AppTableRow>[
        for (final SalesPoint p in series.reversed)
          AppTableRow(
            cells: <Widget>[
              TableCells.twoLine(Fmt.date(p.date), _weekdayName(p.date)),
              TableCells.count(p.invoices),
              TableCells.amount(p.sales),
              TableCells.amount(p.tax, color: AppColors.textSecondary),
              TableCells.amount(p.profit, color: AppColors.success),
            ],
          ),
      ],
      footer: ReportFooterTotals(
        totals: <(String, String)>[
          ('إجمالي الفواتير', Fmt.count(reports.totalInvoices)),
          ('إجمالي المبيعات', Fmt.money(reports.totalSales)),
          ('إجمالي الأرباح', Fmt.money(reports.totalProfit)),
        ],
      ),
    );
  }
}
