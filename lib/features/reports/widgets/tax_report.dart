import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/stat_card.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/reports_controller.dart';
import '../models/report_period.dart';
import 'report_body.dart';
import 'tax_report_table.dart';

/// التقرير الضريبي: بطاقات + الإقرار الشهري.
class TaxReport extends StatelessWidget {
  const TaxReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportsController reports = context.watch<ReportsController>();
    final String taxPercent =
        (reports.tax.taxRate * 100).toStringAsFixed(0);

    return ReportBody(
      summary: <Widget>[
        StatCard(
          title: 'المبيعات الخاضعة للضريبة',
          value: Fmt.moneyRounded(reports.totalSales),
          icon: Icons.point_of_sale_rounded,
          iconColor: AppColors.accent,
          changeLabel: reports.period.label,
        ),
        StatCard(
          title: 'ضريبة محصّلة',
          value: Fmt.moneyRounded(reports.taxCollected),
          icon: Icons.arrow_downward_rounded,
          iconColor: AppColors.success,
          changePercent: 12.4,
          changeLabel: '$taxPercent% من المبيعات',
        ),
        StatCard(
          title: 'ضريبة مشتريات',
          value: Fmt.moneyRounded(reports.taxPaid),
          icon: Icons.arrow_upward_rounded,
          iconColor: AppColors.warning,
          changePercent: 9.1,
          changeLabel: 'قابلة للخصم',
        ),
        StatCard(
          title: 'صافي المستحق للمصلحة',
          value: Fmt.moneyRounded(reports.taxNet),
          icon: Icons.account_balance_outlined,
          iconColor: AppColors.danger,
          higherIsBetter: false,
          changePercent: 14.8,
          changeLabel: 'محصّلة − مشتريات',
        ),
      ],
      content: const TaxReportTable(),
    );
  }
}
