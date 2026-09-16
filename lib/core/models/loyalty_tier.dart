/// مستوى عضوية زي ما الإعدادات بتعرّفه.
///
/// العميل بيوصل للمستوى بإجمالي مشترياته، وبياخد خصم تلقائي على كل فاتورة.
class LoyaltyTier {
  const LoyaltyTier({
    required this.key,
    required this.name,
    required this.minPurchases,
    this.discountPercent = 0,
    this.benefits = const <String>[],
  });

  factory LoyaltyTier.fromJson(Map<String, dynamic> json) => LoyaltyTier(
    key: json['key'] as String? ?? '',
    name: json['name'] as String? ?? '',
    minPurchases: (json['minPurchases'] as num?)?.toDouble() ?? 0,
    discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
    benefits: (json['benefits'] as List<dynamic>? ?? <dynamic>[])
        .whereType<String>()
        .toList(growable: false),
  );

  /// silver / gold / platinum — نفس قيمة `tier` على العميل.
  final String key;
  final String name;
  final double minPurchases;
  final double discountPercent;
  final List<String> benefits;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    'name': name,
    'minPurchases': minPurchases,
    'discountPercent': discountPercent,
    'benefits': benefits,
  };

  LoyaltyTier copyWith({
    String? name,
    double? minPurchases,
    double? discountPercent,
    List<String>? benefits,
  }) => LoyaltyTier(
    key: key,
    name: name ?? this.name,
    minPurchases: minPurchases ?? this.minPurchases,
    discountPercent: discountPercent ?? this.discountPercent,
    benefits: benefits ?? this.benefits,
  );
}

/// نسبة خصم مستوى العميل — صفر للعادي أو لمستوى مش متعرّف.
double tierDiscountPercentFor(String tier, List<LoyaltyTier> tiers) {
  for (final LoyaltyTier t in tiers) {
    if (t.key == tier) return t.discountPercent;
  }
  return 0;
}

/// اسم المستوى من الإعدادات، والاسم الافتراضي لو مش موجود فيها.
String tierNameFor(String tier, List<LoyaltyTier> tiers) {
  for (final LoyaltyTier t in tiers) {
    if (t.key == tier) return t.name;
  }

  return switch (tier) {
    'platinum' => 'بلاتيني',
    'gold' => 'ذهبي',
    'silver' => 'فضي',
    'regular' => 'عادي',
    _ => tier,
  };
}
