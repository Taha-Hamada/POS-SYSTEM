import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/cart_controller.dart';
import '../models/cart_line.dart';
import 'cart_item_remove_button.dart';
import 'quantity_stepper.dart';

/// سطر صنف واحد داخل السلة.
class CartItemTile extends StatefulWidget {
  const CartItemTile({super.key, required this.line});

  final CartLine line;

  @override
  State<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<CartItemTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final CartLine line = widget.line;
    final CartController cart = context.read<CartController>();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md + 2,
        ),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surfaceHover : AppColors.surface,
          border: const Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: line.product.accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Text(
                    line.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyMedium.copyWith(
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedOpacity(
                  opacity: _hovered ? 1 : 0.45,
                  duration: const Duration(milliseconds: 140),
                  child: CartItemRemoveButton(
                    color: _hovered ? AppColors.danger : AppColors.textMuted,
                    onTap: () => cart.removeLine(line),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Row(
              children: <Widget>[
                QuantityStepper(
                  quantity: line.quantity,
                  onIncrement: () => cart.changeQuantity(line, 1),
                  onDecrement: () => cart.changeQuantity(line, -1),
                  onTyped: (double value) => cart.setQuantity(line, value),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '${Fmt.amount(line.product.price)} × ${Fmt.qty(line.quantity)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 11.5),
                  ),
                ),
                Text(
                  Fmt.money(line.total),
                  style: AppText.amountSm.copyWith(fontSize: 14.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
