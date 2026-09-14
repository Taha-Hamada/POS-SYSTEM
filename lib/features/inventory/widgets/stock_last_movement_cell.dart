import 'package:flutter/material.dart';


import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// خلية آخر حركة: التاريخ + كام يوم فاتوا عليه.
class StockLastMovementCell extends StatelessWidget {
  const StockLastMovementCell({super.key, required this.date});

  final DateTime date;

  String get _relativeDays {
    final int days = DateTime.now().difference(date).inDays;
    return switch (days) {
      <= 0 => 'اليوم',
      1 => 'أمس',
      < 7 => 'منذ $days أيام',
      < 14 => 'منذ أسبوع',
      _ => 'منذ ${(days / 7).floor()} أسابيع',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(Fmt.date(date), style: AppText.body.copyWith(fontSize: 13)),
        const SizedBox(height: 2),
        Text(_relativeDays, style: AppText.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}
