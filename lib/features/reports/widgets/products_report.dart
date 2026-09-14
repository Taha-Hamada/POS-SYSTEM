import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/stat_card.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../dashboard/models/dashboard_data.dart';
import '../models/report_period.dart';
import '../controllers/reports_controller.dart';
import 'products_report_table.dart';
import 'report_body.dart';

/// تقرير المنتجات — الأصناف الأكثر مبيعًا وربحية.
class ProductsReport extends StatelessWidget {
  const ProductsReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportsController reports = context.watch<ReportsController>();
    final List<TopProduct> stats = reports.topProducts;
    final String periodLabel = reports.period.label;

    final double totalUnits =
        stats.fold<double>(0, (double s, TopProduct p) => s + p.units);
    final double totalRevenue =
        stats.fold<double>(0, (double s, TopProduct p) => s + p.revenue);
    final double totalProfit =
        stats.fold<double>(0, (double s, TopProduct p) => s + p.profit);

    return ReportBody(
      summary: <Widget>[
        StatCard(
          title: 'أصناف تم بيعها',
          value: Fmt.count(stats.length),
          icon: Icons.inventory_2_outlined,
          iconColor: AppColors.accent,
          changeLabel: periodLabel,
        ),
        StatCard(
          title: 'إجمالي الوحدات',
          value: Fmt.count(totalUnits.round()),
          icon: Icons.numbers_rounded,
          iconColor: AppColors.info,
          changeLabel: periodLabel,
        ),
        StatCard(
          title: 'الأكثر مبيعًا',
          value: stats.isEmpty ? '—' : stats.first.name,
          icon: Icons.emoji_events_outlined,
          iconColor: AppColors.warning,
          changeLabel: stats.isEmpty
              ? '—'
              : Fmt.moneyRounded(stats.first.revenue),
        ),
        StatCard(
          title: 'ربح الأصناف',
          value: Fmt.moneyRounded(totalProfit),
          icon: Icons.savings_outlined,
          iconColor: AppColors.success,
          changeLabel: totalRevenue == 0
              ? periodLabel
              : 'هامش ${(totalProfit / totalRevenue * 100).toStringAsFixed(1)}%',
        ),
      ],
      content: const ProductsReportTable(),
    );
  }
}
