import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/stat_card.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/reports_controller.dart';
import 'inventory_report_table.dart';
import 'report_body.dart';

/// تقرير المخزون: بطاقات + قيمة المخزون حسب الفئة.
class InventoryReport extends StatelessWidget {
  const InventoryReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportsController reports = context.watch<ReportsController>();
    final double totalCost = reports.inventoryTotalCost;
    final double totalRetail = reports.inventoryTotalRetail;

    return ReportBody(
      summary: <Widget>[
        StatCard(
          title: 'قيمة المخزون بالتكلفة',
          value: Fmt.moneyRounded(totalCost),
          icon: Icons.warehouse_outlined,
          iconColor: AppColors.accent,
          changePercent: 6.4,
          changeLabel:
              reports.branchId == null ? 'كل الفروع' : 'الفرع المختار',
        ),
        StatCard(
          title: 'قيمة المخزون بالبيع',
          value: Fmt.moneyRounded(totalRetail),
          icon: Icons.sell_outlined,
          iconColor: AppColors.info,
          changePercent: 7.2,
          changeLabel: 'لو اتباع كامل',
        ),
        StatCard(
          title: 'الربح المتوقع',
          value: Fmt.moneyRounded(totalRetail - totalCost),
          icon: Icons.savings_outlined,
          iconColor: AppColors.success,
          changeLabel: 'الفرق بين البيع والتكلفة',
        ),
        StatCard(
          title: 'عدد الأقسام',
          value: Fmt.count(reports.inventoryRows.length),
          icon: Icons.category_outlined,
          iconColor: AppColors.info,
          changeLabel: 'أقسام فيها رصيد',
        ),
      ],
      content: const InventoryReportTable(),
    );
  }
}
