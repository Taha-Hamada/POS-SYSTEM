import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../dashboard/models/dashboard_data.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// إعدادات رسم أعمدة المبيعات — مفصولة عن الويدجت عشان الملف يفضل مقروء.
abstract final class SalesBarChartData {
  /// [points] لازم تكون مش فاضية.
  static BarChartData build(List<SalesPoint> points) {
    final double maxY = points
            .map((SalesPoint p) => p.sales)
            .reduce((double a, double b) => a > b ? a : b) *
        1.2;
    final double labelInterval = (points.length / 8).ceilToDouble();

    return BarChartData(
      maxY: maxY,
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (double value) => const FlLine(
          color: AppColors.border,
          strokeWidth: 1,
          dashArray: <int>[6, 6],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            interval: maxY / 4,
            getTitlesWidget: (double value, TitleMeta meta) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Text(
                Fmt.compact(value),
                style: AppText.caption.copyWith(fontSize: 10.5),
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: labelInterval,
            getTitlesWidget: (double value, TitleMeta meta) {
              final int i = value.round();
              if (i < 0 || i >= points.length) {
                return const SizedBox.shrink();
              }
              final DateTime d = points[i].date;
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  '${d.day}/${d.month}',
                  style: AppText.caption.copyWith(fontSize: 10.5),
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: _touchData(points),
      barGroups: <BarChartGroupData>[
        for (int i = 0; i < points.length; i++)
          BarChartGroupData(
            x: i,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: points[i].sales,
                width: points.length > 30 ? 6 : 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: <Color>[Color(0xFF8B5CF6), AppColors.accent],
                ),
              ),
            ],
          ),
      ],
    );
  }

  static BarTouchData _touchData(List<SalesPoint> points) {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (BarChartGroupData group) => AppColors.primary,
        tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
        getTooltipItem: (
          BarChartGroupData group,
          int groupIndex,
          BarChartRodData rod,
          int rodIndex,
        ) =>
            BarTooltipItem(
          Fmt.money(rod.toY),
          const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          children: <TextSpan>[
            TextSpan(
              text: '\n${Fmt.date(points[groupIndex].date)}',
              style: const TextStyle(
                color: AppColors.textOnDarkMuted,
                fontWeight: FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
