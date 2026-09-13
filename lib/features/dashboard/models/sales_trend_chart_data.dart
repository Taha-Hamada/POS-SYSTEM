import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'dashboard_data.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// إعدادات رسم اتجاه المبيعات — مفصولة عن الويدجت عشان الملف يفضل مقروء.
abstract final class SalesTrendChartData {
  /// [points] لازم تكون مش فاضية.
  static LineChartData build(List<SalesPoint> points) {
    final double maxY = points
            .map((SalesPoint p) => p.sales)
            .reduce((double a, double b) => a > b ? a : b) *
        1.18;
    final double minY = points
            .map((SalesPoint p) => p.sales)
            .reduce((double a, double b) => a < b ? a : b) *
        0.72;

    // عدد التسميات على المحور الأفقي بيتظبط حسب طول الفترة
    final double labelInterval = (points.length / 6).ceilToDouble();

    return LineChartData(
      minY: minY,
      maxY: maxY,
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) / 4,
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
            interval: (maxY - minY) / 4,
            getTitlesWidget: (double value, TitleMeta meta) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Text(
                Fmt.compact(value),
                style: AppText.caption.copyWith(fontSize: 10.5),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
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
      lineTouchData: _touchData(points),
      lineBarsData: <LineChartBarData>[_bar(points)],
    );
  }

  static LineTouchData _touchData(List<SalesPoint> points) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (LineBarSpot spot) => AppColors.primary,
        tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
        tooltipPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        getTooltipItems: (List<LineBarSpot> spots) => <LineTooltipItem>[
          for (final LineBarSpot s in spots)
            LineTooltipItem(
              Fmt.money(s.y),
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '\n${Fmt.date(points[s.x.round()].date)}',
                  style: const TextStyle(
                    color: AppColors.textOnDarkMuted,
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
        ],
      ),
      getTouchedSpotIndicator: (
        LineChartBarData barData,
        List<int> indexes,
      ) =>
          <TouchedSpotIndicatorData>[
        for (final int _ in indexes)
          TouchedSpotIndicatorData(
            const FlLine(
              color: AppColors.accent,
              strokeWidth: 1.5,
              dashArray: <int>[4, 4],
            ),
            FlDotData(
              getDotPainter: (
                FlSpot spot,
                double percent,
                LineChartBarData bar,
                int index,
              ) =>
                  FlDotCirclePainter(
                radius: 5,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: AppColors.accent,
              ),
            ),
          ),
      ],
    );
  }

  static LineChartBarData _bar(List<SalesPoint> points) {
    return LineChartBarData(
      spots: <FlSpot>[
        for (int i = 0; i < points.length; i++)
          FlSpot(i.toDouble(), points[i].sales),
      ],
      isCurved: true,
      curveSmoothness: 0.28,
      barWidth: 3,
      isStrokeCapRound: true,
      gradient: const LinearGradient(
        colors: <Color>[AppColors.accent, Color(0xFF8B5CF6)],
      ),
      dotData: FlDotData(
        show: points.length <= 14,
        getDotPainter: (
          FlSpot spot,
          double percent,
          LineChartBarData bar,
          int index,
        ) =>
            FlDotCirclePainter(
          radius: 3.5,
          color: Colors.white,
          strokeWidth: 2.5,
          strokeColor: AppColors.accent,
        ),
      ),
      // التدرّج تحت الخط
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.accent.withValues(alpha: 0.28),
            AppColors.accent.withValues(alpha: 0.02),
          ],
        ),
      ),
    );
  }
}
