import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/reports_controller.dart';
import '../models/report_rows.dart';
import '../models/report_period.dart';
import 'report_footer_totals.dart';

/// جدول الإقرار الضريبي الشهري.
class TaxReportTable extends StatelessWidget {
  const TaxReportTable({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportsController reports = context.watch<ReportsController>();
    final List<MonthlyTaxRow> rows = reports.monthlyTaxRows;

    return AppDataTable(
      title: 'الإقرار الضريبي الشهري',
      subtitle: 'ملخص شهري عن ${reports.period.label}',
      minWidth: 820,
      rowHeight: 58,
      columns: const <AppTableColumn>[
        AppTableColumn('الشهر', size: ColumnSize.M),
        AppTableColumn('الفواتير', size: ColumnSize.S, numeric: true),
        AppTableColumn('المبيعات', size: ColumnSize.M, numeric: true),
        AppTableColumn('الضريبة المحصّلة', size: ColumnSize.M, numeric: true),
        AppTableColumn('الحالة', size: ColumnSize.M),
      ],
      rows: <AppTableRow>[
        for (final MonthlyTaxRow r in rows)
          AppTableRow(
            cells: <Widget>[
              Text(
                r.label,
                style: AppText.bodyMedium.copyWith(fontSize: 13.5),
              ),
              TableCells.count(r.invoices),
              TableCells.amount(r.sales),
              TableCells.amount(r.tax, color: AppColors.success),
              StatusBadge(
                label: r.isCurrentMonth ? 'جارٍ' : 'تم التقديم',
                tone: r.isCurrentMonth
                    ? StatusTone.warning
                    : StatusTone.success,
                compact: true,
              ),
            ],
          ),
      ],
      footer: ReportFooterTotals(
        totals: <(String, String)>[
          ('على الفواتير', Fmt.money(reports.taxCharged)),
          // الضريبة اللي رجعت مع المرتجعات مش محصّلة، فبتتخصم.
          if (reports.taxRefunded > 0)
            ('ردّت للعملاء', '− ${Fmt.money(reports.taxRefunded)}'),
          ('محصّلة', Fmt.money(reports.taxCollected)),
          ('مشتريات', Fmt.money(reports.taxPaid)),
          ('الصافي', Fmt.money(reports.taxNet)),
        ],
      ),
    );
  }
}
