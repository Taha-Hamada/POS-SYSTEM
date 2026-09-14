import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../stock_transfer_stocktake/screens/stock_transfer_dialog.dart';
import '../controllers/inventory_controller.dart';

/// هيدر شاشة المخزون: العنوان وأزرار التحويل والجرد.
class InventoryHeader extends StatelessWidget {
  const InventoryHeader({super.key});

  Future<void> _openTransferDialog(BuildContext context) async {
    final InventoryController inventory =
        context.read<InventoryController>();

    final bool? done = await showStockTransferDialog(
      context,
      fromBranchId: inventory.branchId,
    );
    if (done != true || !context.mounted) return;

    // التحويل غيّر أرصدة الفرع، فالجدول لازم يتحدّث.
    await inventory.load();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'نظرة عامة على المخزون',
                style: AppText.pageTitle.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 3),
              Text(
                'متابعة الأرصدة والحركات عبر كل الفروع والمخازن',
                style: AppText.caption,
              ),
            ],
          ),
        ),
        SecondaryButton(
          label: 'تحويل مخزون',
          icon: Icons.swap_horiz_rounded,
          onPressed: () => _openTransferDialog(context),
        ),
        const SizedBox(width: AppSpacing.md),
        SecondaryButton(
          label: 'بدء جرد',
          icon: Icons.fact_check_outlined,
          tone: SecondaryButtonTone.accent,
          onPressed: () => context.go('/inventory/stocktake'),
        ),
      ],
    );
  }
}
