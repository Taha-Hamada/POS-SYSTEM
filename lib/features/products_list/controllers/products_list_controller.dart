import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../data/products_repository.dart';
import '../models/products_filter.dart';
import '../models/products_sort_column.dart';

/// حالة شاشة المنتجات: البحث، الفئة، التبويب المختار، والفرز.
///
/// البيانات بتتجاب من الـ API مرة واحدة، والفلترة والفرز بيحصلوا محليًا
/// عشان التبويبات تعرض أعدادها الصح من غير طلب لكل تبويب.
class ProductsListController extends ChangeNotifier with LoadState {
  ProductsListController(this._repository, {this.branchId});

  final ProductsRepository _repository;
  final String? branchId;

  final TextEditingController searchController = TextEditingController();

  List<Product> _all = <Product>[];
  List<Category> _categories = <Category>[];

  String _query = '';
  String? _categoryId;
  ProductsFilter _filter = ProductsFilter.all;
  int _sortIndex = 0;
  bool _sortAscending = true;

  /// البحث بيستنى شوية بعد آخر حرف بدل ما يعيد الحساب مع كل ضغطة.
  Timer? _searchDebounce;

  /// نتيجة الفلترة والفرز — بتتحسب مرة واحدة لحد ما حاجة تتغيّر.
  List<Product>? _cachedRows;

  String get query => _query;
  String? get categoryId => _categoryId;
  ProductsFilter get filter => _filter;
  int get sortIndex => _sortIndex;
  bool get sortAscending => _sortAscending;

  List<Category> get categories => _categories;
  bool get isEmpty => !isLoading && !hasFailed && _all.isEmpty;

  List<Product> get rows => _cachedRows ??= _computeRows();

  int get visibleCount => rows.length;

  double get visibleValue =>
      rows.fold<double>(0, (double s, Product p) => s + p.price * p.stock);

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      // الاتنين مستقلين، فبيتجابوا على التوازي.
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchAll(branchId: branchId),
        _repository.fetchCategories(),
      ]);

      _all = results[0] as List<Product>;
      _categories = results[1] as List<Category>;
      _cachedRows = null;
    });
  }

  Future<void> retry() => load();

  // ── الفلترة والفرز ───────────────────────────────────────────────────────
  List<Product> _computeRows() {
    final String needle = _query.trim().toLowerCase();

    Iterable<Product> items = _all;

    if (needle.isNotEmpty) {
      items = items.where(
        (Product p) =>
            p.name.toLowerCase().contains(needle) ||
            p.sku.toLowerCase().contains(needle) ||
            (p.barcode?.contains(needle) ?? false) ||
            p.brand.toLowerCase().contains(needle),
      );
    }

    if (_categoryId != null) {
      items = items.where((Product p) => p.categoryId == _categoryId);
    }

    items = switch (_filter) {
      ProductsFilter.all => items,
      ProductsFilter.lowStock =>
        items.where((Product p) => p.isLowStock || p.isOutOfStock),
      ProductsFilter.inactive => items.where((Product p) => !p.isActive),
    };

    final List<Product> list = items.toList();
    final ProductsSortColumn column = ProductsSortColumn.values[_sortIndex];

    list.sort((Product a, Product b) {
      final int result = switch (column) {
        ProductsSortColumn.name => a.name.compareTo(b.name),
        ProductsSortColumn.sku => a.sku.compareTo(b.sku),
        ProductsSortColumn.category => a.categoryName.compareTo(b.categoryName),
        ProductsSortColumn.price => a.price.compareTo(b.price),
        ProductsSortColumn.stock => a.stock.compareTo(b.stock),
        ProductsSortColumn.status => _statusRank(a).compareTo(_statusRank(b)),
      };
      return _sortAscending ? result : -result;
    });

    return list;
  }

  int _statusRank(Product p) {
    if (!p.isActive) return 3;
    if (p.isOutOfStock) return 0;
    if (p.isLowStock) return 1;
    return 2;
  }

  int countFor(ProductsFilter filter) => switch (filter) {
        ProductsFilter.all => _all.length,
        ProductsFilter.lowStock =>
          _all.where((Product p) => p.isLowStock || p.isOutOfStock).length,
        ProductsFilter.inactive => _all.where((Product p) => !p.isActive).length,
      };

  // ── إجراءات ──────────────────────────────────────────────────────────────
  void setQuery(String value) {
    _query = value;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), _refresh);
  }

  void clearSearch() {
    searchController.clear();
    _searchDebounce?.cancel();
    _query = '';
    _refresh();
  }

  void setCategory(String? id) {
    _categoryId = id;
    _refresh();
  }

  void setFilter(ProductsFilter filter) {
    _filter = filter;
    _refresh();
  }

  void sortBy(int columnIndex, bool ascending) {
    _sortIndex = columnIndex;
    _sortAscending = ascending;
    _refresh();
  }

  /// تعطيل منتج بدل مسحه — الفواتير القديمة بتفضل مربوطة بيه.
  /// بترجّع رسالة الخطأ لو فشلت، و`null` لو نجحت.
  Future<String?> setProductActive(String id, {required bool isActive}) async {
    final ApiException? failure = await runAction(() async {
      final Product updated =
          await _repository.setActiveState(id, isActive: isActive);

      final int index = _all.indexWhere((Product p) => p.id == id);
      if (index >= 0) {
        _all[index] = _all[index].copyWith(isActive: updated.isActive);
      }

      _cachedRows = null;
    });

    return failure?.message;
  }

  void _refresh() {
    _cachedRows = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
