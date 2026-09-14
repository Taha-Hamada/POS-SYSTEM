import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/receive_goods_controller.dart';
import '../models/receive_line.dart';
import 'receive_product_cell.dart';
import 'receive_quantity_field.dart';
import 'receive_remaining_badge.dart';

/// صف صنف واحد في جدول الاستلام.
class ReceiveRow extends StatelessWidget {
  const ReceiveRow({
    super.key,
    required this.line,
    required this.isLast,
  });

  final ReceiveLine line;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ReceiveGoodsController receive =
        context.read<ReceiveGoodsController>();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: ReceiveProductCell(line: line.orderLine),
          ),
          SizedBox(
            width: 90,
            child: Text(
              Fmt.count(line.ordered.round()),
              textAlign: TextAlign.center,
              style: AppText.amountSm.copyWith(fontSize: 13.5),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              line.previouslyReceived == 0
                  ? '—'
                  : Fmt.count(line.previouslyReceived.round()),
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: ReceiveQuantityField(
                value: line.receivingNow,
                onChanged: (double v) => receive.setReceivingNow(line, v),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Center(
              child: ReceiveRemainingBadge(remaining: line.remainingAfter),
            ),
          ),
        ],
      ),
    );
  }
}
