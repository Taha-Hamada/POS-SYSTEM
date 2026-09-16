import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/models/customer.dart';
import '../../../core/models/loyalty_tier.dart';
import '../../../core/models/product.dart';
import '../../../core/models/promotion.dart';
import '../../../core/utils/invoice_math.dart';
import '../../../core/utils/promotion_math.dart';
import '../data/pos_repository.dart';
import '../models/cart_discount.dart';
import '../models/cart_line.dart';

/// حالة السلة كاملة: الأصناف، الكميات، العميل، الخصم، وحسابات الفاتورة.
///
/// الأرقام هنا معاينة للكاشير؛ السيرفر بيعيد حسابها وقت الاعتماد.
/// الاتنين بيستخدموا نفس الخطوات، فالرقم المعروض هو الرقم المحصّل.
class CartController extends ChangeNotifier {
  CartController({
    required this.number,
    required double taxRate,
    List<Promotion> promotions = const <Promotion>[],
    List<LoyaltyTier> tiers = const <LoyaltyTier>[],
  }) // الحقول خاصة والباراميترات المسمّاة مينفعش تبدأ بـ«_».
    // ignore: prefer_initializing_formals
    : _taxRate = taxRate,
       // ignore: prefer_initializing_formals
       _promotions = promotions,
       // ignore: prefer_initializing_formals
       _tiers = tiers;

  /// رقم الفاتورة في التبويبات — بيتعرض للكاشير عشان يفرّق بينها.
  final int number;

  double _taxRate;

  /// العروض الشغالة ومستويات العملاء — نفس اللي السيرفر هيطبّقه وقت الاعتماد.
  List<Promotion> _promotions;
  List<LoyaltyTier> _tiers;

  final List<CartLine> _lines = <CartLine>[];
  Customer _customer = const Customer.walkIn();
  CartDiscount _discount = const CartDiscount.none();

  UnmodifiableListView<CartLine> get lines =>
      UnmodifiableListView<CartLine>(_lines);

  Customer get customer => _customer;
  CartDiscount get discount => _discount;
  double get taxRate => _taxRate;
  bool get isEmpty => _lines.isEmpty;
  bool get isNotEmpty => _lines.isNotEmpty;

  /// الإعدادات بتتحمّل بعد ما التبويب يتفتح أحيانًا، فبنحدّث النسبة وقتها.
  void setTaxRate(double rate) {
    if (_taxRate == rate) return;
    _taxRate = rate;
    notifyListeners();
  }

  void setPricingRules({
    List<Promotion>? promotions,
    List<LoyaltyTier>? tiers,
  }) {
    if (promotions != null) _promotions = promotions;
    if (tiers != null) _tiers = tiers;
    notifyListeners();
  }

  // ── حسابات الفاتورة ──────────────────────────────────────────────────────
  /// أحسن عرض للسطر وقيمة خصمه — بيتعرض تحت الصنف في السلة.
  ({Promotion? promotion, double amount}) promotionFor(CartLine line) =>
      bestPromotionFor(
        _promotions,
        productId: line.product.id,
        categoryId: line.product.category?.id,
        quantity: line.quantity,
        unitPrice: line.product.price,
      );

  /// نسبة خصم مستوى العميل — العميل العابر مالوش مستوى.
  double get tierDiscountPercent =>
      _customer.isWalkIn ? 0 : tierDiscountPercentFor(_customer.tier, _tiers);

  String get tierName => tierNameFor(_customer.tier, _tiers);

  InvoiceTotals get totals => calculateTotals(
    lines: <PricedLine>[
      for (final CartLine l in _lines)
        PricedLine(
          unitPrice: l.product.price,
          quantity: l.quantity,
          isTaxable: l.product.isTaxable,
          discountAmount: promotionFor(l).amount,
        ),
    ],
    taxRate: _taxRate,
    // النسبة بتتحسب على الصافي بعد العروض وخصم المستوى، زي السيرفر.
    invoiceDiscount: _discount.isPercentage ? 0 : _discount.value,
    invoiceDiscountPercent: _discount.isPercentage ? _discount.value : 0,
    tierDiscountPercent: tierDiscountPercent,
  );

  double get subtotal => totals.subtotal;

  /// كل الخصومات مع بعض: العروض والمستوى واليدوي.
  double get effectiveDiscount => totals.discountTotal;
  double get promotionDiscount => totals.lineDiscountTotal;
  double get tierDiscount => totals.tierDiscount;
  double get manualDiscount => totals.manualDiscount;
  double get tax => totals.taxAmount;
  double get total => totals.total;

  int get itemsCount =>
      _lines.fold<int>(0, (int sum, CartLine l) => sum + l.quantity);

  // ── إجراءات ──────────────────────────────────────────────────────────────
  /// بيرجّع false لو المنتج نافد — الواجهة هي اللي بتعرض التنبيه.
  bool addProduct(Product product) {
    if (product.isOutOfStock) return false;

    final int index = _lines.indexWhere(
      (CartLine l) => l.product.id == product.id,
    );

    if (index == -1) {
      _lines.insert(0, CartLine(product: product));
    } else {
      // مبنزوّدش فوق المتاح في المخزن، عشان السيرفر ميرفضش الفاتورة كلها بعدين.
      if (_exceedsStock(_lines[index], 1)) return false;
      _lines[index].quantity++;
    }

    notifyListeners();
    return true;
  }

  /// بيرجّع false لو الزيادة هتعدّي الرصيد المتاح.
  bool changeQuantity(CartLine line, int delta) {
    if (delta > 0 && _exceedsStock(line, delta)) return false;

    final int next = line.quantity + delta;
    if (next <= 0) {
      _lines.remove(line);
    } else {
      line.quantity = next;
    }

    notifyListeners();
    return true;
  }

  bool _exceedsStock(CartLine line, int delta) {
    if (!line.product.trackStock) return false;
    return line.quantity + delta > line.product.available;
  }

  void removeLine(CartLine line) {
    _lines.remove(line);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    _customer = const Customer.walkIn();
    _discount = const CartDiscount.none();
    notifyListeners();
  }

  void setCustomer(Customer customer) {
    _customer = customer;
    notifyListeners();
  }

  void setDiscount(CartDiscount discount) {
    _discount = discount;
    notifyListeners();
  }

  /// بيملا السلة من فاتورة معلّقة اترجّعت من السيرفر.
  ///
  /// المنتجات بتتاخد من الكتالوج المحمّل عشان نعرف رصيدها الحالي؛
  /// أي صنف اتشال من الكتالوج بيتجاهل بدل ما يكسر الاسترجاع.
  void restoreFrom(
    List<({Product product, int quantity})> restored, {
    Customer? customer,
    CartDiscount? discount,
  }) {
    _lines
      ..clear()
      ..addAll(<CartLine>[
        for (final ({Product product, int quantity}) item in restored)
          CartLine(product: item.product, quantity: item.quantity),
      ]);

    if (customer != null) _customer = customer;
    if (discount != null) _discount = discount;

    notifyListeners();
  }

  /// سطور الفاتورة بالشكل اللي السيرفر بيستقبله.
  List<InvoiceLineInput> toInvoiceLines() => <InvoiceLineInput>[
    for (final CartLine l in _lines)
      InvoiceLineInput(productId: l.product.id, quantity: l.quantity),
  ];

  /// الخصم بالشكل اللي السيرفر بيستقبله، أو null لو مفيش خصم.
  DiscountInput? toDiscountInput() {
    if (_discount.isEmpty) return null;

    return DiscountInput(
      type: _discount.isPercentage ? 'percentage' : 'fixed',
      value: _discount.value,
    );
  }
}
