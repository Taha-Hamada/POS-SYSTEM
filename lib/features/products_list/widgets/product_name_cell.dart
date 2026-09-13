import 'package:flutter/material.dart';

import '../../../core/models/product.dart';
import '../../../theme/app_theme.dart';

/// خلية المنتج: صورة مصغرة دائرية + الاسم + الماركة.
class ProductNameCell extends StatelessWidget {
  const ProductNameCell({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: <Color>[
                product.accentColor.withValues(alpha: 0.22),
                product.accentColor.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: product.accentColor.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(
            product.categoryIcon,
            size: 19,
            color: product.accentColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMedium.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 2),
              Text(
                product.brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
