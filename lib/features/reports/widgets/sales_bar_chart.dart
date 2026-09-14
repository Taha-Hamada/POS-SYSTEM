import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../dashboard/models/dashboard_data.dart';
import '../../../theme/app_theme.dart';
import '../models/sales_bar_chart_data.dart';

/// بطاقة رسم أعمدة حركة المبيعات.
class SalesBarChart extends StatelessWidget {
  const SalesBarChart({
    super.key,
    required this.points,
    required this.weekly,
  });

  final List<SalesPoint> points;
  final bool weekly;

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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('حركة المبيعات', style: AppText.sectionTitle),
                    const SizedBox(height: 2),
                    Text(
                      weekly ? 'مجمّعة أسبوعيًا' : 'يوميًا',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(child: BarChart(SalesBarChartData.build(points))),
        ],
      ),
    );
  }
}
