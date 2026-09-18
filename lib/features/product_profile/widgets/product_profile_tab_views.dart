import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/product_profile_controller.dart';
import 'product_branches_tab.dart';
import 'product_details_tab.dart';
import 'product_movements_tab.dart';

/// محتوى تبويبات تفاصيل المنتج — الترتيب لازم يطابق [ProductProfileTab].
class ProductProfileTabViews extends StatelessWidget {
  const ProductProfileTabViews({super.key, required this.canEdit});

  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: context.read<ProductProfileController>().tabController,
      children: <Widget>[
        ProductDetailsTab(canEdit: canEdit),
        const ProductBranchesTab(),
        const ProductMovementsTab(),
      ],
    );
  }
}
