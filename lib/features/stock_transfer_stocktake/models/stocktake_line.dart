import '../../inventory/models/stock_record.dart';

/// صف جرد: الكمية بالنظام + الكمية الفعلية المُدخلة.
class StocktakeLine {
  StocktakeLine({required this.record});

  /// رصيد الصنف في الفرع زي ما السيرفر بيقوله.
  final StockRecord record;

  /// null = لسه ماتجردش
  double? actualQuantity;

  String get productId => record.productId;
  String get name => record.productName;
  String get sku => record.sku;
  String get unit => record.unit;

  double get systemQuantity => record.onHand;

  bool get isCounted => actualQuantity != null;

  double get difference =>
      (actualQuantity ?? systemQuantity) - systemQuantity;

  double get valueDifference => difference * record.cost;

  /// الصف محتاج يتبعت للسيرفر بس لو اتجرد وفيه فرق فعلي.
  bool get needsSubmit => isCounted && difference != 0;
}
