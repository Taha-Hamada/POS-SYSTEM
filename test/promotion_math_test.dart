import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/models/promotion.dart';
import 'package:pos_system/core/utils/promotion_math.dart';

/// العروض في الكاشير لازم تدي نفس خصم promotion.pricing.js في الباك اند.
void main() {
  Promotion promo({
    required PromotionType type,
    double percent = 0,
    int minQuantity = 1,
    int buy = 1,
    int get = 1,
    PromotionScope scope = PromotionScope.all,
    String? categoryId,
    List<String> productIds = const <String>[],
    String name = 'عرض',
  }) => Promotion(
    id: name,
    name: name,
    type: type,
    discountPercent: percent,
    minQuantity: minQuantity,
    buyQuantity: buy,
    getQuantity: get,
    scope: scope,
    categoryId: categoryId,
    productIds: productIds,
    startsAt: DateTime(2026),
    endsAt: DateTime(2027),
  );

  test('اشترِ 2 واحصل على 1 — المجموعة الكاملة بس هي اللي بتتحسب', () {
    final Promotion p = promo(type: PromotionType.buyXGetY, buy: 2, get: 1);

    expect(promotionDiscountFor(p, quantity: 2, unitPrice: 10), 0);
    expect(promotionDiscountFor(p, quantity: 3, unitPrice: 10), 10);
    expect(promotionDiscountFor(p, quantity: 7, unitPrice: 10), 20);
  });

  test('خصم الكمية بيشتغل من الحد الأدنى', () {
    final Promotion p = promo(
      type: PromotionType.quantityDiscount,
      percent: 20,
      minQuantity: 10,
    );

    expect(promotionDiscountFor(p, quantity: 9, unitPrice: 4), 0);
    expect(promotionDiscountFor(p, quantity: 10, unitPrice: 4), 8);
  });

  test('العميل بياخد أكبر عرض ينطبق على الصنف بس', () {
    final List<Promotion> promotions = <Promotion>[
      promo(
        name: 'buy2get1',
        type: PromotionType.buyXGetY,
        buy: 2,
        get: 1,
        scope: PromotionScope.products,
        productIds: <String>['p1'],
      ),
      promo(
        name: 'qty',
        type: PromotionType.quantityDiscount,
        percent: 20,
        minQuantity: 10,
        scope: PromotionScope.category,
        categoryId: 'c2',
      ),
      promo(name: 'all5', type: PromotionType.percentage, percent: 5),
    ];

    final ({Promotion? promotion, double amount}) p1 = bestPromotionFor(
      promotions,
      productId: 'p1',
      categoryId: 'c1',
      quantity: 3,
      unitPrice: 10,
    );
    expect(p1.promotion?.name, 'buy2get1');
    expect(p1.amount, 10);

    final ({Promotion? promotion, double amount}) p2 = bestPromotionFor(
      promotions,
      productId: 'p2',
      categoryId: 'c2',
      quantity: 10,
      unitPrice: 4,
    );
    expect(p2.promotion?.name, 'qty');
    expect(p2.amount, 8);

    // صنف مفيش عرض خاص بيه بياخد العرض العام.
    final ({Promotion? promotion, double amount}) other = bestPromotionFor(
      promotions,
      productId: 'p9',
      categoryId: 'c9',
      quantity: 2,
      unitPrice: 50,
    );
    expect(other.promotion?.name, 'all5');
    expect(other.amount, 5);
  });

  test('الحالة من التواريخ والإيقاف', () {
    final DateTime now = DateTime(2026, 6, 1);

    expect(
      promo(type: PromotionType.percentage).statusAt(now),
      PromotionStatus.active,
    );
    expect(
      Promotion(
        id: 's',
        name: 's',
        type: PromotionType.percentage,
        startsAt: DateTime(2026, 7),
        endsAt: DateTime(2026, 8),
      ).statusAt(now),
      PromotionStatus.scheduled,
    );
    expect(
      Promotion(
        id: 'x',
        name: 'x',
        type: PromotionType.percentage,
        startsAt: DateTime(2026),
        endsAt: DateTime(2027),
        isActive: false,
      ).statusAt(now),
      PromotionStatus.stopped,
    );
  });
}
