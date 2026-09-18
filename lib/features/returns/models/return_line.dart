import 'returnable_invoice.dart';

/// صف مرتجع — بيحمل الكمية اللي هتترجّع من سطر الفاتورة.
class ReturnLine {
  ReturnLine({required this.source})
      : returnQuantity = source.remainingQuantity > 0
            ? (source.remainingQuantity < 1 ? source.remainingQuantity : 1)
            : 0;

  /// السطر زي ما السيرفر رجّعه، بكميته المتبقية.
  final ReturnableLine source;

  bool selected = false;
  double returnQuantity;

  /// الصنف رجع سليم ولا تالف — التالف مبيرجعش للمخزون.
  bool restock = true;

  String get name => source.name;
  String get sku => source.sku;
  String get unit => source.unit;
  String get productId => source.productId;

  double get maxQuantity => source.remainingQuantity;
  double get unitPrice => source.unitPrice;

  /// نصيب الكمية المرتجعة من السطر — نفس نسبة السيرفر بالظبط.
  double get _ratio =>
      source.soldQuantity == 0 ? 0 : returnQuantity / source.soldQuantity;

  /// قيمة السطر المرتجعة، بعد خصم السطر وقبل خصم الفاتورة.
  double get refundAmount => source.lineTotal * _ratio;

  /// ضريبة السطر المرتجعة — بتتاخد من الفاتورة مش بضرب نسبة الضريبة،
  /// عشان الأصناف المعفاة وخصم الفاتورة يتحسبوا صح.
  double get refundTax => source.taxAmount * _ratio;
}
