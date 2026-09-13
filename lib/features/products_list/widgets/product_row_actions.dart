import 'package:flutter/material.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/models/product.dart';
import 'delete_product_dialog.dart';
import 'product_row_action.dart';

/// أزرار التعديل والحذف — بتظهر عند الـHover على الصف بس.
class ProductRowActions extends StatelessWidget {
  const ProductRowActions({
    super.key,
    required this.product,
    required this.hovered,
  });

  final Product product;
  final bool hovered;

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDeleteProductDialog(context, product);
    if (confirmed != true || !context.mounted) return;

    showPlainSnackBar(
      context,
      'تم حذف «${product.name}» (تجريبي — البيانات وهمية)',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: hovered ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: IgnorePointer(
        ignoring: !hovered,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ProductRowAction(
              icon: Icons.edit_outlined,
              tooltip: 'تعديل المنتج',
              onTap: () =>
                  showPlainSnackBar(context, 'تعديل «${product.name}»'),
            ),
            const SizedBox(width: 6),
            ProductRowAction(
              icon: Icons.delete_outline_rounded,
              tooltip: 'حذف المنتج',
              danger: true,
              onTap: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}
