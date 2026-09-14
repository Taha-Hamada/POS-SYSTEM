import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../models/payment_entry.dart';
import '../../../core/models/payment_method.dart';
import 'payment_mini_action.dart';

/// سطر دفعة متسجّلة مع زرار إزالتها.
class PaymentEntryRow extends StatelessWidget {
  const PaymentEntryRow({
    super.key,
    required this.entry,
    required this.onRemove,
  });

  final PaymentEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: entry.method.color.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              entry.method.icon,
              size: 15,
              color: entry.method.color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              entry.method.label,
              style: AppText.bodyMedium.copyWith(fontSize: 13.5),
            ),
          ),
          Text(
            Fmt.money(entry.amount),
            style: AppText.amountSm.copyWith(fontSize: 14),
          ),
          const SizedBox(width: AppSpacing.sm),
          PaymentMiniAction(
            icon: Icons.close_rounded,
            tooltip: 'إزالة الدفعة',
            onTap: onRemove,
            danger: true,
          ),
        ],
      ),
    );
  }
}
