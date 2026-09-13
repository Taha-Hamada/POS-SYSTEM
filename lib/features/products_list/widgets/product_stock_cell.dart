import 'package:flutter/material.dart';

import '../../../core/models/product.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// خلية الكمية — بتبقى حمرا لو أقل من 10.
class ProductStockCell extends StatelessWidget {
  const ProductStockCell({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final bool low = product.stock < 10;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          Fmt.count(product.stock),
          style: AppText.amountSm.copyWith(
            color: low ? AppColors.danger : AppColors.textPrimary,
            fontWeight: low ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(product.unit, style: AppText.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}
