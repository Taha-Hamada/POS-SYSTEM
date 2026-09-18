import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/cart_controller.dart';

/// رأس بطاقة السلة: العنوان + عدد الأصناف + زر الإفراغ.
class CartHeader extends StatelessWidget {
  const CartHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cart = context.watch<CartController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.shopping_cart_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Flexible(
            child: Text(
              'الفاتورة الحالية',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sectionTitle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (cart.itemsCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${Fmt.qty(cart.itemsCount)} صنف',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          const Spacer(),
          if (cart.isNotEmpty)
            IconButton(
              tooltip: 'إفراغ السلة',
              onPressed: cart.clear,
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              color: AppColors.textMuted,
            ),
        ],
      ),
    );
  }
}
