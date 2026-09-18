/// تطبيق العروض على سطر في الكاشير.
///
/// نسخة من `promotion.pricing.js` في الباك اند خطوة بخطوة، عشان الخصم اللي
/// الكاشير بيشوفه قبل الدفع هو نفس اللي السيرفر هيحسبه وقت الاعتماد.
library;

import '../models/promotion.dart';
import 'invoice_math.dart';

/// قيمة خصم عرض واحد على سطر — مبتعديش قيمة السطر أبدًا.
double promotionDiscountFor(
  Promotion promotion, {
  required double quantity,
  required double unitPrice,
}) {
  final double gross = round2(unitPrice * quantity);

  final double amount = switch (promotion.type) {
    PromotionType.percentage => gross * promotion.discountPercent / 100,
    PromotionType.quantityDiscount =>
      quantity >= promotion.minQuantity
          ? gross * promotion.discountPercent / 100
          : 0,
    // كل مجموعة كاملة (اشترِ + مجاني) بتدي القطع المجانية بتاعتها.
    // الكسور مبتدخلش هنا: نص كيلو مش بياخد قطعة مجانية.
    PromotionType.buyXGetY =>
      (quantity ~/ (promotion.buyQuantity + promotion.getQuantity)) *
          promotion.getQuantity *
          unitPrice,
  };

  return round2(amount.clamp(0, gross).toDouble());
}

/// أحسن عرض للسطر وقيمته — العروض مبتتجمعش، العميل بياخد الأكبر بس.
({Promotion? promotion, double amount}) bestPromotionFor(
  List<Promotion> promotions, {
  required String productId,
  required String? categoryId,
  required double quantity,
  required double unitPrice,
}) {
  Promotion? best;
  double bestAmount = 0;

  for (final Promotion promotion in promotions) {
    if (!promotion.appliesTo(productId: productId, categoryId: categoryId)) {
      continue;
    }

    final double amount = promotionDiscountFor(
      promotion,
      quantity: quantity,
      unitPrice: unitPrice,
    );

    // أكبر تمامًا بس، عشان لو اتساووا ياخد نفس العرض اللي السيرفر هياخده.
    if (amount > bestAmount) {
      best = promotion;
      bestAmount = amount;
    }
  }

  return (promotion: best, amount: bestAmount);
}
