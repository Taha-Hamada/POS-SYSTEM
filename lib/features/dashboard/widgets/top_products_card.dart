import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_data.dart';
import '../../../theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';
import 'dashboard_card_header.dart';
import 'top_product_row.dart';

/// بطاقة أفضل 5 منتجات مبيعًا.
class TopProductsCard extends StatelessWidget {
  const TopProductsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<TopProduct> stats =
        context.watch<DashboardController>().topProducts;
    final double max = stats.isEmpty ? 1 : stats.first.revenue;

    return Container(
      decoration: AppDecorations.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const DashboardCardHeader(
            icon: Icons.emoji_events_outlined,
            title: 'أفضل 5 منتجات مبيعًا',
            subtitle: 'حسب قيمة المبيعات خلال الفترة',
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              itemCount: stats.length,
              itemBuilder: (BuildContext context, int i) =>
                  TopProductRow(stat: stats[i], maxRevenue: max, rank: i),
            ),
          ),
        ],
      ),
    );
  }
}
