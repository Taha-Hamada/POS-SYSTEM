import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../theme/app_theme.dart';
import '../controllers/cart_controller.dart';
import '../controllers/sales_session_controller.dart';
import 'pos_search_bar.dart';
import 'product_category_tabs.dart';
import 'product_grid.dart';
import 'products_empty_state.dart';

/// الجزء الأكبر من شاشة الكاشير: البحث + الفئات + شبكة المنتجات.
class ProductsPanel extends StatefulWidget {
  const ProductsPanel({super.key});

  @override
  State<ProductsPanel> createState() => _ProductsPanelState();
}

class _ProductsPanelState extends State<ProductsPanel>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _query = '';

  /// الأقسام بتوصل بعد التحميل، فبنعيد بناء التبويبات لما عددها يتغيّر.
  void _syncTabs(int length) {
    if (_tabController?.length == length) return;

    _tabController?.dispose();
    _tabController = TabController(length: length, vsync: this)
      ..addListener(() {
        if (!_tabController!.indexIsChanging) return;
        setState(() {});
      });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
    _searchFocus.requestFocus();
  }

  void _addToCart(Product product) {
    final bool added = context.read<CartController>().addProduct(product);
    if (added) return;

    showAppSnackBar(
      context,
      product.isOutOfStock
          ? '«${product.name}» نفد من المخزون'
          : 'وصلت لآخر الكمية المتاحة من «${product.name}»',
      isError: true,
    );
  }

  /// مسح باركود: بيضيف الصنف فورًا لو لقاه، عشان الكاشير ميضغطش مرتين.
  Future<void> _onScan(String code) async {
    final SalesSessionController session =
        context.read<SalesSessionController>();

    // بيدوّر محليًا الأول وبعدين على السيرفر، فممكن ياخد لحظة.
    final Product? found = await session.productByBarcode(code);
    if (!mounted) return;

    if (found == null) {
      showAppSnackBar(context, 'مفيش منتج بالكود «$code»', isError: true);
      return;
    }

    _addToCart(found);
    _clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final SalesSessionController session =
        context.watch<SalesSessionController>();

    final List<Category> categories = session.categories;
    _syncTabs(categories.length + 1);

    final int index = _tabController!.index;
    final String? categoryId = index == 0 ? null : categories[index - 1].id;

    final List<Product> products =
        session.search(_query, categoryId: categoryId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PosSearchBar(
          controller: _searchController,
          focusNode: _searchFocus,
          query: _query,
          onChanged: (String v) => setState(() => _query = v),
          onClear: _clearSearch,
          // قارئ الباركود بيكتب الكود وبيضغط Enter، فده هو مدخل المسح.
          onSubmitted: _onScan,
          onScan: () => _searchFocus.requestFocus(),
        ),
        const SizedBox(height: AppSpacing.lg),
        ProductCategoryTabs(controller: _tabController!),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: products.isEmpty
              ? const ProductsEmptyState()
              : ProductGrid(products: products, onProductTap: _addToCart),
        ),
      ],
    );
  }
}
