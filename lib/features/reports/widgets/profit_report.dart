import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/stat_card.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/reports_controller.dart';
import '../models/report_rows.dart';
import '../models/report_period.dart';
import 'profit_report_table.dart';
import 'report_body.dart';

/// تقرير الأرباح: بطاقات + جدول الربحية حسب الفئة.
class ProfitReport extends StatelessWidget {
  const ProfitReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportsController reports = context.watch<ReportsController>();
    final List<CategoryReportRow> rows = reports.categoryRows;
    final String periodLabel = reports.period.label;

    final double revenue =
        rows.fold<double>(0, (double s, CategoryReportRow r) => s + r.revenue);
    final double cost =
        rows.fold<double>(0, (double s, CategoryReportRow r) => s + r.cost);
    final double profit = revenue - cost;

    return ReportBody(
      summary: <Widget>[
        StatCard(
          title: 'إجمالي الإيراد',
          value: Fmt.moneyRounded(revenue),
          icon: Icons.attach_money_rounded,
          iconColor: AppColors.accent,
          changePercent: 14.2,
          changeLabel: periodLabel,
        ),
        StatCard(
          title: 'تكلفة البضاعة المباعة',
          value: Fmt.moneyRounded(cost),
          icon: Icons.shopping_bag_outlined,
          iconColor: AppColors.warning,
          higherIsBetter: false,
          changePercent: 9.8,
          changeLabel: periodLabel,
        ),
        StatCard(
          title: 'صافي الربح',
          value: Fmt.moneyRounded(profit),
          icon: Icons.savings_outlined,
          iconColor: AppColors.success,
          changePercent: 18.6,
          changeLabel: periodLabel,
        ),
        StatCard(
          title: 'هامش الربح',
          value: Fmt.percent(revenue == 0 ? 0 : (profit / revenue) * 100),
          icon: Icons.percent_rounded,
          iconColor: AppColors.info,
          changePercent: 2.3,
          changeLabel: periodLabel,
        ),
      ],
      content: const ProfitReportTable(),
    );
  }
}
