import 'package:flutter/material.dart';

import '../../../core/models/product.dart';
import '../../../theme/app_theme.dart';
import 'product_card.dart';

/// شبكة بطاقات المنتجات.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 215,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.83,
      ),
      itemCount: products.length,
      itemBuilder: (BuildContext context, int i) => ProductCard(
        product: products[i],
        onTap: () => onProductTap(products[i]),
      ),
    );
  }
}
