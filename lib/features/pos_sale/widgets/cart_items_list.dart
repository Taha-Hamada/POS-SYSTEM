import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/cart_controller.dart';
import '../models/cart_line.dart';
import 'cart_item_tile.dart';

/// قائمة أصناف السلة.
class CartItemsList extends StatelessWidget {
  const CartItemsList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<CartLine> lines = context.watch<CartController>().lines;

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: lines.length,
      itemBuilder: (BuildContext context, int i) => CartItemTile(
        key: ValueKey<String>(
          '${lines[i].product.id}-${lines[i].pricingMode.name}-${i}',
        ),
        line: lines[i],
      ),
    );
  }
}
