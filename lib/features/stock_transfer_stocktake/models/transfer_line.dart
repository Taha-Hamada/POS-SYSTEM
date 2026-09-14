import '../../inventory/models/stock_record.dart';

/// صف منتج داخل أمر التحويل.
class TransferLine {
  TransferLine({required this.record, this.quantity = 1});

  /// رصيد الصنف في الفرع المُرسِل.
  final StockRecord record;

  int quantity;

  String get productId => record.productId;
  String get name => record.productName;
  String get sku => record.sku;
  String get unit => record.unit;

  /// المتاح للتحويل — المحجوز للفواتير المعلّقة مطروح منه.
  int get available => record.available;

  bool get exceedsAvailable => quantity > available;

  double get value => record.cost * quantity;
}
