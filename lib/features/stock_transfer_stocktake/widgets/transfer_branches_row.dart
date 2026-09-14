import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/stock_transfer_controller.dart';
import 'transfer_branch_field.dart';
import 'transfer_swap_button.dart';

/// صف اختيار الفرع المُرسِل والمُستقبِل + تنبيه لو الاتنين نفس الفرع.
class TransferBranchesRow extends StatelessWidget {
  const TransferBranchesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final StockTransferController transfer =
        context.watch<StockTransferController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TransferBranchField(
                label: 'الفرع المُرسِل',
                value: transfer.fromBranchId,
                icon: Icons.upload_rounded,
                color: AppColors.warning,
                branches: transfer.branches,
                onChanged: transfer.setFromBranch,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TransferSwapButton(onTap: transfer.swapBranches),
            ),
            Expanded(
              child: TransferBranchField(
                label: 'الفرع المُستقبِل',
                value: transfer.toBranchId ?? transfer.fromBranchId,
                icon: Icons.download_rounded,
                color: AppColors.success,
                branches: transfer.branches,
                onChanged: transfer.setToBranch,
              ),
            ),
          ],
        ),
        if (transfer.sameBranch) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                size: 15,
                color: AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'لا يمكن التحويل إلى نفس الفرع — اختر فرعًا مختلفًا.',
                style: AppText.caption.copyWith(color: AppColors.danger),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
