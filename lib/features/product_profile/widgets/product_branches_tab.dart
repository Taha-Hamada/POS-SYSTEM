import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../inventory/models/product_branch_stock.dart';
import '../controllers/product_profile_controller.dart';

/// تبويب الأرصدة — رصيد المنتج في كل فرع ليه سجل.
class ProductBranchesTab extends StatelessWidget {
  const ProductBranchesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductProfileController p = context
        .watch<ProductProfileController>();

    if (p.branchStock.isEmpty) {
      return const EmptyView(
        title: 'المنتج ملوش رصيد في أي فرع',
        description:
            'أول ما تتسجل عليه حركة — شراء أو رصيد افتتاحي أو تحويل — '
            'هيبان هنا بالفرع بتاعه.',
        icon: Icons.store_mall_directory_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: p.branchStock.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int i) =>
          _BranchRow(stock: p.branchStock[i], unit: p.product?.unit ?? ''),
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({required this.stock, required this.unit});

  final ProductBranchStock stock;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(radius: AppRadius.md),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.store_mall_directory_outlined,
              size: 18,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  stock.branchName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMedium.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  stock.lastCountedAt == null
                      ? 'لسه ماتجردش'
                      : 'آخر جرد ${Fmt.date(stock.lastCountedAt!)}',
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          Expanded(child: _cell('الرصيد', '${Fmt.qty(stock.quantity)} $unit')),
          Expanded(child: _cell('حد الطلب', Fmt.count(stock.minStock))),
          StatusBadge.stock(
            stock: stock.quantity,
            minStock: stock.minStock,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _cell(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(label, style: AppText.label.copyWith(fontSize: 11)),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.amountSm.copyWith(fontSize: 13.5),
      ),
    ],
  );
}
