import 'package:flutter/material.dart';

enum PromotionType {
  percentage('percentage', 'خصم نسبة', Icons.percent_rounded),
  buyXGetY('buy_x_get_y', 'اشترِ واحصل', Icons.card_giftcard_rounded),
  quantityDiscount('quantity_discount', 'خصم كمية', Icons.inventory_2_rounded);

  const PromotionType(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;

  static PromotionType fromApi(String? value) =>
      PromotionType.values.firstWhere(
        (PromotionType t) => t.apiValue == value,
        orElse: () => percentage,
      );
}

enum PromotionScope {
  all('all', 'كل المنتجات'),
  category('category', 'قسم معيّن'),
  products('products', 'منتجات مختارة');

  const PromotionScope(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PromotionScope fromApi(String? value) => PromotionScope.values
      .firstWhere((PromotionScope s) => s.apiValue == value, orElse: () => all);
}

enum PromotionStatus {
  active('active', 'نشط'),
  scheduled('scheduled', 'مجدول'),
  expired('expired', 'منتهي'),
  stopped('stopped', 'متوقف');

  const PromotionStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// عرض جاي من الـ API.
class Promotion {
  const Promotion({
    required this.id,
    required this.name,
    required this.type,
    required this.startsAt,
    required this.endsAt,
    this.description = '',
    this.discountPercent = 0,
    this.minQuantity = 1,
    this.buyQuantity = 1,
    this.getQuantity = 1,
    this.scope = PromotionScope.all,
    this.categoryId,
    this.categoryName,
    this.productIds = const <String>[],
    this.isActive = true,
    this.usageCount = 0,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    // القسم والمنتجات بيرجعوا كائنات في القايمة، ومعرّفات بس في العروض الشغالة.
    final dynamic category = json['category'];
    final List<dynamic> products =
        json['products'] as List<dynamic>? ?? <dynamic>[];

    return Promotion(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: PromotionType.fromApi(json['type'] as String?),
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      minQuantity: (json['minQuantity'] as num?)?.toInt() ?? 1,
      buyQuantity: (json['buyQuantity'] as num?)?.toInt() ?? 1,
      getQuantity: (json['getQuantity'] as num?)?.toInt() ?? 1,
      scope: PromotionScope.fromApi(json['scope'] as String?),
      categoryId: category is Map<String, dynamic>
          ? category['id'] as String?
          : category as String?,
      categoryName: category is Map<String, dynamic>
          ? category['name'] as String?
          : null,
      productIds: <String>[
        for (final dynamic p in products)
          if (p is Map<String, dynamic>) p['id'] as String? ?? '' else '$p',
      ],
      startsAt:
          DateTime.tryParse(json['startsAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      endsAt:
          DateTime.tryParse(json['endsAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String description;
  final PromotionType type;
  final double discountPercent;
  final int minQuantity;
  final int buyQuantity;
  final int getQuantity;
  final PromotionScope scope;
  final String? categoryId;
  final String? categoryName;
  final List<String> productIds;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;
  final int usageCount;

  /// نفس قاعدة السيرفر: الإيقاف اليدوي الأول، وبعدين التواريخ.
  PromotionStatus statusAt(DateTime now) {
    if (!isActive) return PromotionStatus.stopped;
    if (startsAt.isAfter(now)) return PromotionStatus.scheduled;
    if (endsAt.isBefore(now)) return PromotionStatus.expired;
    return PromotionStatus.active;
  }

  PromotionStatus get status => statusAt(DateTime.now());

  bool get isLive => status == PromotionStatus.active;

  int get durationDays => endsAt.difference(startsAt).inDays + 1;

  /// نسبة ما مضى من مدة العرض — للشريط تحت البطاقة.
  double get elapsedRatio {
    final DateTime now = DateTime.now();
    if (!now.isAfter(startsAt)) return 0;
    if (now.isAfter(endsAt)) return 1;

    final int total = endsAt.difference(startsAt).inSeconds;
    if (total <= 0) return 1;
    return (now.difference(startsAt).inSeconds / total).clamp(0, 1).toDouble();
  }

  /// القيمة بشكل مختصر للبطاقة: «15%» أو «2+1» أو «20% من 10 قطع».
  String get valueLabel => switch (type) {
    PromotionType.percentage => '${_percent(discountPercent)}%',
    PromotionType.buyXGetY => '$buyQuantity+$getQuantity',
    PromotionType.quantityDiscount =>
      '${_percent(discountPercent)}% من $minQuantity قطع',
  };

  String get scopeLabel => switch (scope) {
    PromotionScope.all => 'كل المنتجات',
    PromotionScope.category => 'قسم ${categoryName ?? ''}'.trim(),
    PromotionScope.products => '${productIds.length} منتج مختار',
  };

  static String _percent(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  /// العرض يخص الصنف ده؟
  bool appliesTo({required String productId, String? categoryId}) =>
      switch (scope) {
        PromotionScope.all => true,
        PromotionScope.category =>
          categoryId != null && categoryId == this.categoryId,
        PromotionScope.products => productIds.contains(productId),
      };
}
