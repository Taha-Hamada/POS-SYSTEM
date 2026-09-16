import 'loyalty_tier.dart';

/// إعدادات المتجر الجاية من الـ API.
///
/// الضريبة والعملة وسياسات البيع بتتقرا مرة واحدة بعد الدخول،
/// عشان شاشة الكاشير تحسب نفس أرقام السيرفر قبل ما تبعت الفاتورة.
class StoreSettings {
  const StoreSettings({
    this.storeName = 'متجري',
    this.storeAddress = '',
    this.storePhone = '',
    this.taxNumber = '',
    this.currency = 'EGP',
    this.taxRate = 0,
    this.pricesIncludeTax = false,
    this.receiptFooter = '',
    this.receiptWidthMm = 80,
    this.pointsPerCurrency = 0,
    this.currencyPerPoint = 0,
    this.minPointsToRedeem = 0,
    this.loyaltyTiers = const <LoyaltyTier>[],
    this.notifyLowStock = true,
    this.notifyExpiry = true,
    this.allowNegativeStock = false,
    this.requireCustomerForCredit = true,
    this.requireOpenShift = true,
  });

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> notifications =
        (json['notifications'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return StoreSettings._fromJson(json, notifications);
  }

  factory StoreSettings._fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> notifications,
  ) => StoreSettings(
    storeName: json['storeName'] as String? ?? 'متجري',
    storeAddress: json['storeAddress'] as String? ?? '',
    storePhone: json['storePhone'] as String? ?? '',
    taxNumber: json['taxNumber'] as String? ?? '',
    currency: json['currency'] as String? ?? 'EGP',
    taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
    pricesIncludeTax: json['pricesIncludeTax'] as bool? ?? false,
    receiptFooter: json['receiptFooter'] as String? ?? '',
    receiptWidthMm: (json['receiptWidthMm'] as num?)?.toInt() ?? 80,
    pointsPerCurrency: (json['pointsPerCurrency'] as num?)?.toDouble() ?? 0,
    currencyPerPoint: (json['currencyPerPoint'] as num?)?.toDouble() ?? 0,
    minPointsToRedeem: (json['minPointsToRedeem'] as num?)?.toInt() ?? 0,
    loyaltyTiers: (json['loyaltyTiers'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(LoyaltyTier.fromJson)
        .toList(growable: false),
    notifyLowStock: notifications['lowStock'] as bool? ?? true,
    notifyExpiry: notifications['expiry'] as bool? ?? true,
    allowNegativeStock: json['allowNegativeStock'] as bool? ?? false,
    requireCustomerForCredit: json['requireCustomerForCredit'] as bool? ?? true,
    requireOpenShift: json['requireOpenShift'] as bool? ?? true,
  );

  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String taxNumber;
  final String currency;

  /// نسبة من 0 لـ 1 — 0.14 يعني 14%.
  final double taxRate;
  final bool pricesIncludeTax;
  final String receiptFooter;

  /// عرض ورق الإيصال بالملّي (58 أو 80 غالبًا).
  final int receiptWidthMm;

  final double pointsPerCurrency;
  final double currencyPerPoint;
  final int minPointsToRedeem;

  /// مستويات العضوية مرتبة تصاعديًا بالحد الأدنى للمشتريات.
  final List<LoyaltyTier> loyaltyTiers;

  /// تنبيهات الجرس: نواقص المخزون والصلاحية القريبة.
  final bool notifyLowStock;
  final bool notifyExpiry;

  final bool allowNegativeStock;
  final bool requireCustomerForCredit;
  final bool requireOpenShift;

  /// النسبة كعدد صحيح للعرض: 0.14 تبقى 14.
  double get taxPercent => taxRate * 100;
}
