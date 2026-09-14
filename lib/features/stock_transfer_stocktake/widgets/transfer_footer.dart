import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../controllers/stock_transfer_controller.dart';

/// فوتر الحوار: اتجاه التحويل وأزرار الإلغاء والتنفيذ.
///
/// التحويل بيتنفذ فورًا على السيرفر، فمفيش مراحل — زرار واحد بيخلّص الأمر.
class TransferFooter extends StatelessWidget {
  const TransferFooter({super.key});

  Future<void> _submit(BuildContext context) async {
    final StockTransferController transfer =
        context.read<StockTransferController>();

    final TransferResult result = await transfer.submit();
    if (!context.mounted) return;

    if (result.failed > 0) {
      showAppSnackBar(
        context,
        result.error ?? 'فشل تحويل ${result.failed} صنف',
        isError: true,
      );
      return;
    }

    showAppSnackBar(context, 'اتحوّل ${result.moved} صنف');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final StockTransferController transfer =
        context.watch<StockTransferController>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(AppRadius.xl),
          bottomLeft: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    '${transfer.fromName}  ←  ${transfer.toName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          SecondaryButton(
            label: 'إلغاء',
            size: AppButtonSize.large,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.md),
          PrimaryButton(
            label: 'تنفيذ التحويل',
            icon: Icons.send_rounded,
            size: AppButtonSize.large,
            onPressed: transfer.canSubmit ? () => _submit(context) : null,
          ),
        ],
      ),
    );
  }
}
