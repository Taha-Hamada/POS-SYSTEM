import 'dart:collection';

import 'package:flutter/foundation.dart' hide Category;

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/category.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/product.dart';
import '../../../core/models/promotion.dart';
import '../../../core/models/store_settings.dart';
import '../data/pos_repository.dart';
import '../models/cart_line.dart';
import 'cart_controller.dart';

/// بيدير شاشة الكاشير كلها: الكتالوج والتبويبات المفتوحة.
///
/// التبويبات مسوّدات محلية في الذاكرة، والاعتماد بس هو اللي بيروح للسيرفر
/// ويخصم المخزون.
class SalesSessionController extends ChangeNotifier with LoadState {
  SalesSessionController(this._repository, {this.branchId});

  final PosRepository _repository;
  final String? branchId;

  final List<CartController> _carts = <CartController>[];

  List<Product> _products = <Product>[];
  List<Category> _categories = <Category>[];
  StoreSettings _settings = const StoreSettings();
  List<Promotion> _promotions = <Promotion>[];

  int _activeIndex = 0;
  int _nextNumber = 1;

  UnmodifiableListView<CartController> get carts =>
      UnmodifiableListView<CartController>(_carts);

  UnmodifiableListView<Product> get products =>
      UnmodifiableListView<Product>(_products);

  UnmodifiableListView<Category> get categories =>
      UnmodifiableListView<Category>(_categories);

  StoreSettings get settings => _settings;

  int get activeIndex => _activeIndex;
  CartController get active => _carts[_activeIndex];

  /// آخر تبويب مبيتقفلش — لازم يفضل فيه فاتورة واحدة على الأقل.
  bool get canCloseTabs => _carts.length > 1;

  bool get hasCatalog => _products.isNotEmpty;

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchProducts(branchId: branchId),
        _repository.fetchCategories(),
        _repository.fetchSettings(),
        _repository.fetchLivePromotions(),
      ]);

      _products = results[0] as List<Product>;
      _categories = results[1] as List<Category>;
      _settings = results[2] as StoreSettings;
      _promotions = results[3] as List<Promotion>;

      if (_carts.isEmpty) {
        _carts.add(_newCart());
      } else {
        for (final CartController cart in _carts) {
          cart
            ..setTaxRate(_settings.taxRate)
            ..setPricingRules(promotions: _promotions);
        }
      }
    });
  }

  Future<void> retry() => load();

  /// كل تبويب جديد بياخد نفس الضريبة والعروض.
  CartController _newCart() => CartController(
    number: _nextNumber++,
    taxRate: _settings.taxRate,
    promotions: _promotions,
  );

  /// العروض الشغالة دلوقتي — لو اتغيرت وسط اليوم السيرفر هو المرجع وقت الدفع.
  UnmodifiableListView<Promotion> get promotions =>
      UnmodifiableListView<Promotion>(_promotions);

  /// بيعدّل رصيد المنتجات محليًا بعد بيعة خصمته.
  ///
  /// إعادة تحميل الكتالوج كله بعد كل بيعة كانت بتعمل طلبات كتير من غير داعي:
  /// إحنا عارفين الكميات اللي اتباعت، فبنطبّق الفرق على النسخة اللي عندنا.
  void _applySoldQuantities(Map<String, double> sold) {
    if (sold.isEmpty) return;

    _products = _products.map((Product p) {
      final double delta = sold[p.id] ?? 0;
      if (delta == 0 || !p.trackStock) return p;

      return p.copyWith(stock: p.stock - delta);
    }).toList();

    notifyListeners();
  }

  /// بيعيد قراءة الكتالوج من السيرفر — للسحب لتحديث أو بعد خطأ في المزامنة.
  Future<void> refreshCatalog() async {
    try {
      _products = await _repository.fetchProducts(branchId: branchId);
      notifyListeners();
    } on ApiException {
      // فشل التحديث مش سبب لتعطيل الشاشة؛ الأرصدة هتبقى قديمة شوية بس.
    }
  }

  /// كميات كل منتج في سلة، بالشكل اللي [_applySoldQuantities] بيستقبله.
  Map<String, double> _quantitiesOf(CartController cart) {
    final Map<String, double> quantities = <String, double>{};

    for (final CartLine line in cart.lines) {
      quantities[line.product.id] =
          (quantities[line.product.id] ?? 0) + line.quantity;
    }

    return quantities;
  }

  // ── البحث في الكتالوج ────────────────────────────────────────────────────
  List<Product> search(String query, {String? categoryId}) {
    final String needle = query.trim().toLowerCase();

    return _products.where((Product p) {
      if (categoryId != null && p.categoryId != categoryId) return false;
      if (needle.isEmpty) return true;

      return p.name.toLowerCase().contains(needle) ||
          p.sku.toLowerCase().contains(needle) ||
          (p.barcode?.contains(needle) ?? false) ||
          p.brand.toLowerCase().contains(needle);
    }).toList();
  }

  /// بيدوّر على الكود في الكتالوج المحمّل، وبعدين على السيرفر.
  ///
  /// الكتالوج بيتحمّل مرة واحدة أول ما الشاشة تفتح، فالمنتج اللي اتضاف أو
  /// اتعدّل باركوده بعد كده مكانش بيتلاقي خالص. اللقية الجديدة بتتضاف
  /// للكتالوج عشان المسحة اللي بعدها تبقى محلية.
  Future<Product?> productByBarcode(String barcode) async {
    final String code = barcode.trim();
    if (code.isEmpty) return null;

    for (final Product p in _products) {
      if (p.barcode == code || p.sku.toLowerCase() == code.toLowerCase()) {
        return p;
      }
    }

    try {
      final Product? found = await _repository.findByBarcode(
        code,
        branchId: branchId,
      );
      if (found == null || !found.isActive) return null;

      _products = <Product>[..._products, found];
      notifyListeners();
      return found;
    } on ApiException {
      // السيرفر مش راد — بنقول مفيش منتج بدل ما نكسر المسح.
      return null;
    }
  }

  // ── التبويبات ────────────────────────────────────────────────────────────
  void switchTo(int index) {
    if (index < 0 || index >= _carts.length || index == _activeIndex) return;
    _activeIndex = index;
    notifyListeners();
  }

  void openNew() {
    _carts.add(_newCart());
    _activeIndex = _carts.length - 1;
    notifyListeners();
  }

  void closeAt(int index) {
    if (!canCloseTabs || index < 0 || index >= _carts.length) return;

    _carts.removeAt(index).dispose();
    if (_activeIndex >= _carts.length) _activeIndex = _carts.length - 1;
    notifyListeners();
  }

  // ── الاعتماد ─────────────────────────────────────────────────────────────
  /// بيبعت الفاتورة للسيرفر ويرجّعها بأرقامه هو.
  /// بيرمي [ApiException] لو رفضها، عشان الشاشة تعرض السبب زي ما هو.
  Future<CompletedInvoice> checkout(List<PaymentInput> payments) async {
    final Map<String, double> quantities = _quantitiesOf(active);

    final CompletedInvoice invoice = await _repository.checkout(
      lines: active.toInvoiceLines(),
      payments: payments,
      customerId: active.customer.isWalkIn ? null : active.customer.id,
      discount: active.toDiscountInput(),
    );

    _applySoldQuantities(quantities);
    _closeOrClearActive();
    notifyListeners();

    return invoice;
  }

  Future<List<Customer>> searchCustomers(String query) =>
      _repository.searchCustomers(query);

  Future<Customer> createCustomer({
    required String name,
    required String phone,
  }) => _repository.createCustomer(name: name, phone: phone);

  void _closeOrClearActive() {
    if (canCloseTabs) {
      _carts.removeAt(_activeIndex).dispose();
      if (_activeIndex >= _carts.length) _activeIndex = _carts.length - 1;
    } else {
      active.clear();
    }
  }

  @override
  void dispose() {
    for (final CartController c in _carts) {
      c.dispose();
    }
    super.dispose();
  }
}
