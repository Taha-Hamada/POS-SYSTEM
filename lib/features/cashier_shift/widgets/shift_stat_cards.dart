import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/shift_controller.dart';
import '../models/shift_stat.dart';
import 'shift_mini_stat_card.dart';

/// بطاقات إحصائيات الوردية.
///
/// العدد بيتغيّر حسب اللي فيه قيمة (مرتجعات، مصروفات…)، فبتتلف على أكتر
/// من سطر بدل ما تتزنق كلها في صف واحد.
class ShiftStatCards extends StatelessWidget {
  const ShiftStatCards({super.key});

  /// أقصى عدد بطاقات في السطر — أكتر من كده الأرقام بتتقطع.
  static const int _perRow = 5;

  @override
  Widget build(BuildContext context) {
    final List<ShiftStat> stats = context.read<ShiftController>().stats;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int perRow = stats.length <= _perRow ? stats.length : _perRow;
        final double width =
            (constraints.maxWidth - AppSpacing.md * (perRow - 1)) / perRow;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            for (final ShiftStat stat in stats)
              SizedBox(width: width, child: ShiftMiniStatCard(stat: stat)),
          ],
        );
      },
    );
  }
}
