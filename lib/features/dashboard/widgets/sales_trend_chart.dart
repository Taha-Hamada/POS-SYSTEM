import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/dashboard_data.dart';
import '../../../theme/app_theme.dart';
import '../models/sales_trend_chart_data.dart';
import 'chart_legend_dot.dart';

/// بطاقة رسم اتجاه المبيعات.
class SalesTrendChart extends StatelessWidget {
  const SalesTrendChart({
    super.key,
    required this.points,
    required this.periodLabel,
  });

  final List<SalesPoint> points;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  size: 19,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('اتجاه المبيعات', style: AppText.sectionTitle),
                    const SizedBox(height: 2),
                    Text(periodLabel, style: AppText.caption),
                  ],
                ),
              ),
              const ChartLegendDot(
                color: AppColors.accent,
                label: 'المبيعات اليومية',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(child: LineChart(SalesTrendChartData.build(points))),
        ],
      ),
    );
  }
}
