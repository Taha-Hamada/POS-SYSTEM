import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../inventory/models/stock_record.dart';
import '../controllers/stock_transfer_controller.dart';
import '../models/transfer_line.dart';
import 'transfer_product_picker.dart';
import 'transfer_line_row.dart';
import 'transfer_lines_empty.dart';
import 'transfer_lines_header.dart';
import 'transfer_lines_total.dart';

/// جدول الأصناف المحوّلة مع زرار الإضافة والإجمالي.
class TransferLinesTable extends StatelessWidget {
  const TransferLinesTable({super.key});

  Future<void> _addProduct(BuildContext context) async {
    final StockTransferController transfer =
        context.read<StockTransferController>();

    final StockRecord? picked = await showTransferProductPicker(
      context,
      stock: transfer.availableStock,
      excludedIds: transfer.pickedProductIds,
    );
    if (picked == null) return;

    transfer.addProduct(picked);
  }

  @override
  Widget build(BuildContext context) {
    final StockTransferController transfer =
        context.watch<StockTransferController>();
    final List<TransferLine> lines = transfer.lines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('الأصناف المحوّلة', style: AppText.cardTitle),
            const SizedBox(width: AppSpacing.sm),
            if (lines.isNotEmpty)
              Text('(${Fmt.count(lines.length)})', style: AppText.caption),
            const Spacer(),
            SecondaryButton(
              label: 'إضافة صنف',
              icon: Icons.add_rounded,
              size: AppButtonSize.small,
              tone: SecondaryButtonTone.accent,
              onPressed:
                  !transfer.isLoading ? () => _addProduct(context) : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: AppDecorations.card(radius: AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              const TransferLinesHeader(),
              if (lines.isEmpty)
                const TransferLinesEmpty()
              else
                for (int i = 0; i < lines.length; i++)
                  TransferLineRow(
                    key: ObjectKey(lines[i]),
                    line: lines[i],
                    isLast: i == lines.length - 1,
                  ),
              if (lines.isNotEmpty) const TransferLinesTotal(),
            ],
          ),
        ),
      ],
    );
  }
}
