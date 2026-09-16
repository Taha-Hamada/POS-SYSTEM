import '../../../core/models/promotion.dart';

/// بيانات عرض جديد أو تعديل عرض موجود وهي رايحة للسيرفر.
class PromotionInput {
  const PromotionInput({
    required this.name,
    required this.type,
    required this.startsAt,
    required this.endsAt,
    this.discountPercent = 0,
    this.minQuantity = 1,
    this.buyQuantity = 1,
    this.getQuantity = 1,
    this.scope = PromotionScope.all,
    this.categoryId,
    this.productIds = const <String>[],
  });

  final String name;
  final PromotionType type;
  final double discountPercent;
  final int minQuantity;
  final int buyQuantity;
  final int getQuantity;
  final PromotionScope scope;
  final String? categoryId;
  final List<String> productIds;
  final DateTime startsAt;
  final DateTime endsAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'type': type.apiValue,
    'discountPercent': discountPercent,
    'minQuantity': minQuantity,
    'buyQuantity': buyQuantity,
    'getQuantity': getQuantity,
    'scope': scope.apiValue,
    // الحقول اللي مش بتاعة النطاق المختار بتتبعت فاضية عشان تتمسح على السيرفر.
    'category': scope == PromotionScope.category ? categoryId : null,
    'products': scope == PromotionScope.products
        ? productIds
        : const <String>[],
    'startsAt': startsAt.toUtc().toIso8601String(),
    'endsAt': endsAt.toUtc().toIso8601String(),
  };
}
