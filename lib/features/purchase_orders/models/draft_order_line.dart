/// صف في أمر الشراء الجديد.
class DraftOrderLine {
  DraftOrderLine({
    required this.productId,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.unitCost,
    this.unit = '',
    this.stock = 0,
  });

  final String productId;
  final String name;
  final String sku;
  final String unit;

  /// رصيد الصنف وقت ما اتضاف للأمر — بيساعد اللي بيطلب يقرر الكمية.
  final int stock;

  int quantity;
  double unitCost;

  double get total => quantity * unitCost;
}
