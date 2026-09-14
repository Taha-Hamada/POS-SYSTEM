import 'returnable_invoice.dart';

/// صف مرتجع — بيحمل الكمية اللي هتترجّع من سطر الفاتورة.
class ReturnLine {
  ReturnLine({required this.source})
      : returnQuantity = source.remainingQuantity > 0 ? 1 : 0;

  /// السطر زي ما السيرفر رجّعه، بكميته المتبقية.
  final ReturnableLine source;

  bool selected = false;
  int returnQuantity;

  /// الصنف رجع سليم ولا تالف — التالف مبيرجعش للمخزون.
  bool restock = true;

  String get name => source.name;
  String get sku => source.sku;
  String get unit => source.unit;
  String get productId => source.productId;

  int get maxQuantity => source.remainingQuantity;
  double get unitPrice => source.unitPrice;

  /// قيمة الإرجاع المعروضة.
  ///
  /// بتتحسب من قيمة السطر بعد خصمه بالتناسب، مش من السعر الأصلي،
  /// عشان الرقم المعروض يطابق اللي السيرفر هيردّه فعلًا.
  double get refundAmount => source.soldQuantity == 0
      ? 0
      : source.lineTotal * (returnQuantity / source.soldQuantity);
}
