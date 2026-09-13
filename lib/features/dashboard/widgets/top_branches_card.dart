import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_data.dart';
import 'dashboard_card_header.dart';
import 'top_branch_row.dart';

/// بطاقة أفضل الفروع أداءً.
class TopBranchesCard extends StatelessWidget {
  const TopBranchesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<BranchStats> rows =
        context.watch<DashboardController>().branchesPerformance;
    final double max = rows.isEmpty ? 1 : rows.first.sales;

    return Container(
      decoration: AppDecorations.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const DashboardCardHeader(
            icon: Icons.storefront_outlined,
            title: 'أفضل الفروع أداءً',
            subtitle: 'ترتيب الفروع حسب المبيعات ونصيب كل فرع',
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              itemCount: rows.length,
              itemBuilder: (BuildContext context, int i) => TopBranchRow(
                performance: rows[i],
                rank: i,
                maxSales: max,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
