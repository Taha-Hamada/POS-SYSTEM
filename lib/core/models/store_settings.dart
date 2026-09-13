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
    this.pointsPerCurrency = 0,
    this.currencyPerPoint = 0,
    this.minPointsToRedeem = 0,
    this.allowNegativeStock = false,
    this.requireCustomerForCredit = true,
    this.requireOpenShift = true,
  });

  factory StoreSettings.fromJson(Map<String, dynamic> json) => StoreSettings(
        storeName: json['storeName'] as String? ?? 'متجري',
        storeAddress: json['storeAddress'] as String? ?? '',
        storePhone: json['storePhone'] as String? ?? '',
        taxNumber: json['taxNumber'] as String? ?? '',
        currency: json['currency'] as String? ?? 'EGP',
        taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
        pricesIncludeTax: json['pricesIncludeTax'] as bool? ?? false,
        receiptFooter: json['receiptFooter'] as String? ?? '',
        pointsPerCurrency: (json['pointsPerCurrency'] as num?)?.toDouble() ?? 0,
        currencyPerPoint: (json['currencyPerPoint'] as num?)?.toDouble() ?? 0,
        minPointsToRedeem: (json['minPointsToRedeem'] as num?)?.toInt() ?? 0,
        allowNegativeStock: json['allowNegativeStock'] as bool? ?? false,
        requireCustomerForCredit:
            json['requireCustomerForCredit'] as bool? ?? true,
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

  final double pointsPerCurrency;
  final double currencyPerPoint;
  final int minPointsToRedeem;

  final bool allowNegativeStock;
  final bool requireCustomerForCredit;
  final bool requireOpenShift;

  /// النسبة كعدد صحيح للعرض: 0.14 تبقى 14.
  double get taxPercent => taxRate * 100;
}
