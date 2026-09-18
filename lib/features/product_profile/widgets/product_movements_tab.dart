import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/async_state_views.dart';
import '../../../theme/app_theme.dart';
import '../../inventory/widgets/stock_movement_tile.dart';
import '../controllers/product_profile_controller.dart';

/// تبويب الحركات — آخر حركات المخزون على المنتج من كل الفروع.
class ProductMovementsTab extends StatelessWidget {
  const ProductMovementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductProfileController p = context
        .watch<ProductProfileController>();

    if (p.movements.isEmpty) {
      return const EmptyView(
        title: 'مفيش حركات على المنتج ده',
        description: 'البيع والشراء والجرد والتحويل كلهم بيتسجلوا هنا.',
        icon: Icons.swap_vert_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: p.movements.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int i) =>
          StockMovementTile(movement: p.movements[i], showBranch: true),
    );
  }
}
