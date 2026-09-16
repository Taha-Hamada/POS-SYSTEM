import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/product.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../controllers/products_list_controller.dart';
import 'delete_product_dialog.dart';
import 'products_list_header.dart';
import 'product_row_action.dart';

/// أزرار التعديل والإيقاف — بتظهر عند الـHover على الصف بس.
class ProductRowActions extends StatelessWidget {
  const ProductRowActions({
    super.key,
    required this.product,
    required this.hovered,
  });

  final Product product;
  final bool hovered;

  /// السيرفر مبيمسحش المنتجات لأن الفواتير القديمة مربوطة بيها،
  /// فالحذف هنا إيقاف: المنتج بيختفي من البيع وبيفضل في التاريخ.
  Future<void> _confirmDeactivate(BuildContext context) async {
    final ProductsListController products = context
        .read<ProductsListController>();

    final bool? confirmed = await showDeleteProductDialog(context, product);
    if (confirmed != true || !context.mounted) return;

    final String? error = await products.setProductActive(
      product.id,
      isActive: false,
    );
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      error ?? 'اتوقف «${product.name}» ومبقاش بيظهر في البيع',
      isError: error != null,
    );
  }

  Future<void> _reactivate(BuildContext context) async {
    final String? error = await context
        .read<ProductsListController>()
        .setProductActive(product.id, isActive: true);
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      error ?? 'رجع «${product.name}» للبيع',
      isError: error != null,
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
                  openOverProducts(context, '/products/${product.id}/edit'),
            ),
            const SizedBox(width: 6),
            if (product.isActive)
              ProductRowAction(
                icon: Icons.block_rounded,
                tooltip: 'إيقاف المنتج',
                danger: true,
                onTap: () => _confirmDeactivate(context),
              )
            else
              ProductRowAction(
                icon: Icons.restore_rounded,
                tooltip: 'إرجاع المنتج للبيع',
                onTap: () => _reactivate(context),
              ),
          ],
        ),
      ),
    );
  }
}
