import 'package:flutter/material.dart';

import '../../../core/models/product.dart';
import '../../../theme/app_theme.dart';

/// خلية الفئة: أيقونة الفئة + اسمها.
class ProductCategoryCell extends StatelessWidget {
  const ProductCategoryCell({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(product.categoryIcon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            product.categoryName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
