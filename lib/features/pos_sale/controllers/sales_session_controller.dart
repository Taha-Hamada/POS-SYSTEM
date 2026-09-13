import 'dart:collection';

import 'package:flutter/foundation.dart' hide Category;

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/category.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/product.dart';
import '../../../core/models/store_settings.dart';
import '../data/pos_repository.dart';
import '../models/cart_discount.dart';
import '../models/held_invoice.dart';
import 'cart_controller.dart';

/// بيدير شاشة الكاشير كلها: الكتالوج، التبويبات المفتوحة، والمعلّقات.
///
/// التبويبات مسوّدات محلية في الذاكرة؛ التعليق والاعتماد بيروحوا للسيرفر،
/// عشان الفاتورة المعلّقة تحجز رصيدها والمعتمدة تخصمه فعلًا.
class SalesSessionController extends ChangeNotifier with LoadState {
  SalesSessionController(this._repository, {this.branchId});

  final PosRepository _repository;
  final String? branchId;

  final List<CartController> _carts = <CartController>[];
  List<HeldInvoice> _held = <HeldInvoice>[];

  List<Product> _products = <Product>[];
  List<Category> _categories = <Category>[];
  StoreSettings _settings = const StoreSettings();

  int _activeIndex = 0;
  int _nextNumber = 1;

  UnmodifiableListView<CartController> get carts =>
      UnmodifiableListView<CartController>(_carts);

  UnmodifiableListView<HeldInvoice> get held =>
      UnmodifiableListView<HeldInvoice>(_held);

  UnmodifiableListView<Product> get products =>
      UnmodifiableListView<Product>(_products);

  UnmodifiableListView<Category> get categories =>
      UnmodifiableListView<Category>(_categories);

  StoreSettings get settings => _settings;

  int get activeIndex => _activeIndex;
  CartController get active => _carts[_activeIndex];
  int get heldCount => _held.length;

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
        _repository.fetchHeld(),
      ]);

      _products = results[0] as List<Product>;
      _categories = results[1] as List<Category>;
      _settings = results[2] as StoreSettings;
      _held = results[3] as List<HeldInvoice>;

      if (_carts.isEmpty) {
        _carts.add(CartController(number: _nextNumber++, taxRate: _settings.taxRate));
      } else {
        for (final CartController cart in _carts) {
          cart.setTaxRate(_settings.taxRate);
        }
      }
    });
  }

  Future<void> retry() => load();

  /// بيعدّل رصيد المنتجات محليًا بعد عملية غيّرته.
  ///
  /// إعادة تحميل الكتالوج كله بعد كل بيعة كانت بتعمل طلبات كتير من غير داعي:
  /// إحنا عارفين الكميات اللي اتغيّرت، فبنطبّق الفرق على النسخة اللي عندنا.
  void _applyStockDeltas(
    Map<String, int> soldOrReserved, {
    required bool reserve,
  }) {
    if (soldOrReserved.isEmpty) return;

    _products = _products.map((Product p) {
      final int delta = soldOrReserved[p.id] ?? 0;
      if (delta == 0 || !p.trackStock) return p;

      return reserve
          ? p.copyWith(reserved: (p.reserved + delta).clamp(0, p.stock))
          : p.copyWith(stock: p.stock - delta);
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

  /// كميات كل منتج في سلة، بالشكل اللي [_applyStockDeltas] بيستقبله.
  Map<String, int> _quantitiesOf(CartController cart) {
    final Map<String, int> quantities = <String, int>{};

    for (final dynamic line in cart.lines) {
      quantities[line.product.id as String] =
          (quantities[line.product.id] ?? 0) + (line.quantity as int);
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

  Product? productByBarcode(String barcode) {
    final String code = barcode.trim();

    for (final Product p in _products) {
      if (p.barcode == code || p.sku.toLowerCase() == code.toLowerCase()) {
        return p;
      }
    }

    return null;
  }

  // ── التبويبات ────────────────────────────────────────────────────────────
  void switchTo(int index) {
    if (index < 0 || index >= _carts.length || index == _activeIndex) return;
    _activeIndex = index;
    notifyListeners();
  }

  void openNew() {
    _carts.add(CartController(number: _nextNumber++, taxRate: _settings.taxRate));
    _activeIndex = _carts.length - 1;
    notifyListeners();
  }

  void closeAt(int index) {
    if (!canCloseTabs || index < 0 || index >= _carts.length) return;

    _carts.removeAt(index).dispose();
    if (_activeIndex >= _carts.length) _activeIndex = _carts.length - 1;
    notifyListeners();
  }

  // ── التعليق والاسترجاع ───────────────────────────────────────────────────
  /// بيعلّق الفاتورة النشطة على السيرفر ويقفل تبويبها.
  /// بيرجّع رسالة الخطأ لو فشل، و`null` لو نجح.
  Future<String?> holdActive({String? label}) async {
    if (active.isEmpty) return null;

    final Map<String, int> quantities = _quantitiesOf(active);

    final ApiException? failure = await runAction(() async {
      final HeldInvoice heldInvoice = await _repository.hold(
        lines: active.toInvoiceLines(),
        customerId: active.customer.isWalkIn ? null : active.customer.id,
        discount: active.toDiscountInput(),
        label: label ?? 'فاتورة ${active.number}',
      );

      _held = <HeldInvoice>[heldInvoice, ..._held];
      _closeOrClearActive();
    });

    // التعليق بيحجز رصيد، فالمتاح للبيع بيقل بنفس الكمية.
    if (failure == null) _applyStockDeltas(quantities, reserve: true);

    return failure?.message;
  }

  /// بيرجّع فاتورة معلّقة في تبويب، وبيشيل حجزها من السيرفر.
  ///
  /// الاسترجاع بيمسح الفاتورة من السيرفر ويرجّع أصنافها للسلة المحلية،
  /// فلو الكاشير سابها من غير دفع، بيقدر يعلّقها من جديد.
  Future<String?> restore(HeldInvoice invoice) async {
    final ApiException? failure = await runAction(() async {
      await _repository.discardHeld(invoice.id);
      _held = _held.where((HeldInvoice h) => h.id != invoice.id).toList();

      final List<({Product product, int quantity})> restored =
          <({Product product, int quantity})>[];

      for (final HeldInvoiceLine line in invoice.lines) {
        final Product? product = _findProduct(line.productId);
        if (product == null) continue;
        restored.add((product: product, quantity: line.quantity));
      }

      // لو التبويب الحالي فاضي بنستخدمه بدل ما نفتح تبويب زيادة.
      final CartController target = active.isEmpty ? active : _openTab();
      target.restoreFrom(restored, discount: const CartDiscount.none());
    });

    if (failure == null) _applyStockDeltas(_heldQuantities(invoice), reserve: true);

    return failure?.message;
  }

  Future<String?> deleteHeld(HeldInvoice invoice) async {
    final ApiException? failure = await runAction(() async {
      await _repository.discardHeld(invoice.id);
      _held = _held.where((HeldInvoice h) => h.id != invoice.id).toList();
    });

    if (failure == null) _applyStockDeltas(_heldQuantities(invoice), reserve: true);

    return failure?.message;
  }

  /// كميات فاتورة معلّقة بالسالب — إلغاؤها أو استرجاعها بيفك حجزها.
  Map<String, int> _heldQuantities(HeldInvoice invoice) => <String, int>{
        for (final HeldInvoiceLine line in invoice.lines)
          line.productId: -line.quantity,
      };

  CartController _openTab() {
    final CartController cart =
        CartController(number: _nextNumber++, taxRate: _settings.taxRate);
    _carts.add(cart);
    _activeIndex = _carts.length - 1;
    return cart;
  }

  Product? _findProduct(String id) {
    for (final Product p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ── الاعتماد ─────────────────────────────────────────────────────────────
  /// بيبعت الفاتورة للسيرفر ويرجّعها بأرقامه هو.
  /// بيرمي [ApiException] لو رفضها، عشان الشاشة تعرض السبب زي ما هو.
  Future<CompletedInvoice> checkout(List<PaymentInput> payments) async {
    final Map<String, int> quantities = _quantitiesOf(active);

    final CompletedInvoice invoice = await _repository.checkout(
      lines: active.toInvoiceLines(),
      payments: payments,
      customerId: active.customer.isWalkIn ? null : active.customer.id,
      discount: active.toDiscountInput(),
    );

    _applyStockDeltas(quantities, reserve: false);
    _closeOrClearActive();
    notifyListeners();

    return invoice;
  }

  Future<List<Customer>> searchCustomers(String query) =>
      _repository.searchCustomers(query);

  Future<Customer> createCustomer({
    required String name,
    required String phone,
  }) =>
      _repository.createCustomer(name: name, phone: phone);

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
