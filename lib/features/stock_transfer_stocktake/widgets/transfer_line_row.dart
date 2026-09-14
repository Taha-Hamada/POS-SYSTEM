import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/stock_transfer_controller.dart';
import '../models/transfer_line.dart';
import 'transfer_quantity_field.dart';

/// صف صنف واحد داخل أمر التحويل.
class TransferLineRow extends StatelessWidget {
  const TransferLineRow({
    super.key,
    required this.line,
    required this.isLast,
  });

  final TransferLine line;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final StockTransferController transfer =
        context.watch<StockTransferController>();
    final bool editable = !transfer.isLoading;

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
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(
                    line.record.categoryIcon,
                    size: 17,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        line.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMedium.copyWith(fontSize: 13),
                      ),
                      Text(
                        line.sku,
                        style: AppText.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${Fmt.count(line.available)} '
              '${line.unit}',
              style: AppText.body.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: TransferQuantityField(
              value: line.quantity,
              enabled: editable,
              hasError: line.exceedsAvailable,
              onChanged: (int v) => transfer.setQuantity(line, v),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Fmt.money(line.value),
              style: AppText.amountSm.copyWith(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              tooltip: 'حذف الصنف',
              onPressed: editable ? () => transfer.removeLine(line) : null,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
