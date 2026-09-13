import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';
import '../../../core/models/product.dart';
import '../../../theme/app_theme.dart';

/// صورة المنتج داخل البطاقة + شارة المخزون + زر الإضافة عند الـHover.
class ProductCardThumbnail extends StatelessWidget {
  const ProductCardThumbnail({
    super.key,
    required this.product,
    required this.showAddButton,
  });

  final Product product;
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    final Product p = product;

    return Stack(
      children: <Widget>[
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: <Color>[
                p.accentColor.withValues(alpha: 0.16),
                p.accentColor.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: AppRadius.mdAll,
          ),
          child: Icon(
            p.categoryIcon,
            size: 34,
            color: p.accentColor,
          ),
        ),
        if (p.isOutOfStock || p.isLowStock)
          PositionedDirectional(
            top: 6,
            start: 6,
            child: StatusBadge.stock(
              stock: p.stock,
              minStock: p.minStock,
              compact: true,
            ),
          ),
        if (showAddButton)
          PositionedDirectional(
            bottom: 6,
            end: 6,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: AppShadows.accentGlow,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
