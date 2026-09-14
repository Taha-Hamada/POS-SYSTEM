import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../theme/app_theme.dart';
import '../controllers/reports_controller.dart';
import '../models/report_rows.dart';
import '../models/report_period.dart';
import 'bar_cell.dart';

/// جدول أداء الموظفين.
class EmployeesReportTable extends StatelessWidget {
  const EmployeesReportTable({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportsController reports = context.watch<ReportsController>();
    final List<EmployeeReportRow> rows = reports.employeeRows;

    final double maxSales =
        rows.isEmpty || rows.first.sales == 0 ? 1 : rows.first.sales;

    return AppDataTable(
      title: 'أداء الموظفين',
      subtitle: 'مبيعات كل كاشير خلال ${reports.period.label}',
      minWidth: 880,
      rowHeight: 62,
      emptyMessage: 'مفيش مبيعات في الفترة دي',
      emptyIcon: Icons.badge_outlined,
      // التقرير بيرجّع أرقام البيع بس؛ الدور والفرع في شاشة الموظفين.
      columns: const <AppTableColumn>[
        AppTableColumn('الكاشير', size: ColumnSize.L),
        AppTableColumn('الفواتير', size: ColumnSize.S, numeric: true),
        AppTableColumn('متوسط الفاتورة', size: ColumnSize.M, numeric: true),
        AppTableColumn('الخصومات', size: ColumnSize.M, numeric: true),
        AppTableColumn('المبيعات', size: ColumnSize.M, numeric: true),
      ],
      rows: <AppTableRow>[
        for (final EmployeeReportRow r in rows)
          AppTableRow(
            cells: <Widget>[
              TableCells.avatarName(
                r.name,
                r.initials,
                color: AppColors.accent,
                subtitle: r.username,
              ),
              TableCells.count(r.invoices),
              TableCells.amount(r.averageTicket,
                  color: AppColors.textSecondary),
              TableCells.amount(r.discounts, color: AppColors.warning),
              BarCell(value: r.sales, max: maxSales),
            ],
          ),
      ],
    );
  }
}
