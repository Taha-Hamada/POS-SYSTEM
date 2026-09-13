import 'package:flutter/material.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../models/held_invoice.dart';

/// سطر فاتورة معلّقة في القائمة.
class HeldInvoiceTile extends StatelessWidget {
  const HeldInvoiceTile({
    super.key,
    required this.invoice,
    required this.onRestore,
    required this.onDelete,
  });

  final HeldInvoice invoice;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: AppRadius.smAll,
            ),
            child: const Icon(
              Icons.pause_circle_outline_rounded,
              size: 20,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${invoice.customerName ?? invoice.label} • '
                  '${Fmt.count(invoice.itemsCount)} صنف',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMedium.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'اتعلّقت ${Fmt.time(invoice.heldAt)}',
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            Fmt.money(invoice.subtotal),
            style: AppText.amountSm.copyWith(fontSize: 14),
          ),
          const SizedBox(width: AppSpacing.md),
          SecondaryButton(
            label: 'حذف',
            size: AppButtonSize.small,
            tone: SecondaryButtonTone.danger,
            onPressed: onDelete,
          ),
          const SizedBox(width: AppSpacing.sm),
          PrimaryButton(
            label: 'استرجاع',
            icon: Icons.play_arrow_rounded,
            size: AppButtonSize.small,
            onPressed: onRestore,
          ),
        ],
      ),
    );
  }
}
