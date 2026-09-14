import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/status_badge.dart';
import '../../../core/models/purchase_order.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/receive_goods_controller.dart';

/// هيدر حوار الاستلام: رقم الأمر والمورد وتاريخه.
class ReceiveGoodsHeader extends StatelessWidget {
  const ReceiveGoodsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final PurchaseOrder order =
        context.read<ReceiveGoodsController>().order;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppRadius.xl),
          topLeft: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(
              Icons.inventory_rounded,
              size: 21,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text('استلام البضاعة', style: AppText.sectionTitle),
                    const SizedBox(width: AppSpacing.sm),
                    StatusBadge(
                      label: order.number,
                      tone: StatusTone.neutral,
                      showDot: false,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.supplierName} • تاريخ الأمر '
                  '${Fmt.date(order.orderDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'إغلاق',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
