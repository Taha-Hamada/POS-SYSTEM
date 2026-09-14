import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../models/draft_order_line.dart';

/// خلية المخزون الحالي وقت ما الصنف اتضاف للأمر.
class DraftLineStockCell extends StatelessWidget {
  const DraftLineStockCell({super.key, required this.line});

  final DraftOrderLine line;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          Fmt.count(line.stock),
          style: AppText.amountSm.copyWith(
            fontSize: 13,
            color: line.stock <= 0
                ? AppColors.danger
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        Text(line.unit, style: AppText.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}
