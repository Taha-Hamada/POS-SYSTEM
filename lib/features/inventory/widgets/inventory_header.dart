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

    // التحويل بيتنفّذ من فرع لفرع، فمن غير فرع مصدر مفيش حاجة نفتحها.
    final String? from = inventory.branchId;
    if (from == null) return;

    final bool? done = await showStockTransferDialog(
      context,
      fromBranchId: from,
    );
    if (done != true || !context.mounted) return;

    // التحويل غيّر أرصدة الفرع، فالجدول لازم يتحدّث.
    await inventory.load();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasBranch =
        context.select((InventoryController i) => i.hasBranch);

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
                'متابعة الأرصدة والحركات في الفرع المختار',
                style: AppText.caption,
              ),
            ],
          ),
        ),
        SecondaryButton(
          label: 'التنبيهات',
          icon: Icons.notification_important_outlined,
          onPressed: () => context.go('/inventory/alerts'),
        ),
        const SizedBox(width: AppSpacing.md),
        SecondaryButton(
          label: 'تحويل مخزون',
          icon: Icons.swap_horiz_rounded,
          onPressed: hasBranch ? () => _openTransferDialog(context) : null,
        ),
        const SizedBox(width: AppSpacing.md),
        SecondaryButton(
          label: 'بدء جرد',
          icon: Icons.fact_check_outlined,
          tone: SecondaryButtonTone.accent,
          onPressed: hasBranch ? () => context.go('/inventory/stocktake') : null,
        ),
      ],
    );
  }
}
