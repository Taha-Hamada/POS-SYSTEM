import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/receive_goods_controller.dart';
import '../models/receive_line.dart';
import 'receive_lines_header.dart';
import 'receive_row.dart';

/// جدول أصناف الاستلام.
class ReceiveLinesTable extends StatelessWidget {
  const ReceiveLinesTable({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ReceiveLine> lines =
        context.watch<ReceiveGoodsController>().lines;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: AppDecorations.card(radius: AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const ReceiveLinesHeader(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: lines.length,
              itemBuilder: (BuildContext context, int i) => ReceiveRow(
                key: ValueKey<String>(lines[i].orderLine.id),
                line: lines[i],
                isLast: i == lines.length - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
