import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/stat_card.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/reports_controller.dart';
import '../models/report_rows.dart';
import '../models/report_period.dart';
import 'employees_report_table.dart';
import 'report_body.dart';

/// تقرير أداء الموظفين: بطاقات + جدول الفريق.
class EmployeesReport extends StatelessWidget {
  const EmployeesReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportsController reports = context.watch<ReportsController>();
    final List<EmployeeReportRow> rows = reports.employeeRows;
    final String periodLabel = reports.period.label;

    return ReportBody(
      summary: <Widget>[
        StatCard(
          title: 'عدد الموظفين',
          value: Fmt.count(rows.length),
          icon: Icons.badge_outlined,
          iconColor: AppColors.accent,
          changeLabel:
              reports.branchId == null ? 'كل الفروع' : 'الفرع المختار',
        ),
        StatCard(
          title: 'مبيعات الفريق',
          value: Fmt.moneyRounded(reports.totalSales),
          icon: Icons.trending_up_rounded,
          iconColor: AppColors.success,
          changeLabel: periodLabel,
        ),
        StatCard(
          title: 'أعلى موظف مبيعًا',
          value: rows.isEmpty ? '—' : rows.first.name,
          icon: Icons.emoji_events_outlined,
          iconColor: AppColors.warning,
          changeLabel:
              rows.isEmpty ? '—' : Fmt.moneyRounded(rows.first.sales),
        ),
        StatCard(
          title: 'متوسط الفاتورة للفريق',
          value: Fmt.money(reports.avgInvoice),
          icon: Icons.shopping_basket_outlined,
          iconColor: AppColors.info,
          changePercent: 4.1,
          changeLabel: periodLabel,
        ),
      ],
      content: const EmployeesReportTable(),
    );
  }
}
