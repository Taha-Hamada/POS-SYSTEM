import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../models/stock_record.dart';

/// سطر حركة مخزون — بيتعرض في حوار حركات الصنف وفي تفاصيل المنتج.
class StockMovementTile extends StatelessWidget {
  const StockMovementTile({
    super.key,
    required this.movement,
    this.showBranch = false,
  });

  final StockMovement movement;

  /// حركات المنتج بتيجي من كل الفروع، فالفرع لازم يبان معاها.
  final bool showBranch;

  @override
  Widget build(BuildContext context) {
    final Color color =
        movement.isIncoming ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              movement.isIncoming
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  movement.reasonLabel,
                  style: AppText.bodyMedium.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  <String>[
                    Fmt.date(movement.createdAt),
                    if (showBranch && movement.branchName.isNotEmpty)
                      movement.branchName,
                    if (movement.performedBy != null) movement.performedBy!,
                    if (movement.note.isNotEmpty) movement.note,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${movement.isIncoming ? '+' : '−'} '
                '${Fmt.count(movement.quantity.abs())}',
                style: AppText.amountSm.copyWith(color: color, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                'الرصيد ${Fmt.count(movement.balanceAfter)}',
                style: AppText.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
