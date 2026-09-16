import 'package:flutter/material.dart';

import '../../../core/api/api_config.dart';
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
    final String? image = ApiConfig.mediaUrl(p.imageUrl);

    final Widget placeholder = Icon(
      p.categoryIcon,
      size: 34,
      color: p.accentColor,
    );

    return Stack(
      children: <Widget>[
        Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
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
          // الصورة لو موجودة، وأيقونة القسم لو مفيش أو التحميل فشل.
          child: image == null
              ? placeholder
              : Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => placeholder,
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
