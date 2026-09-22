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
    this.piecesPerCarton = 1,
  });

  final String productId;
  final String name;
  final String sku;
  final String unit;

  /// رصيد الصنف وقت ما اتضاف للأمر — بيساعد اللي بيطلب يقرر الكمية.
  final double stock;

  /// عدد القطع داخل الكرتونة الواحدة؛ المخزون نفسه يبقى بالقطع دائمًا.
  final int piecesPerCarton;

  int quantity;
  double unitCost;

  int get cartonQuantity => piecesPerCarton > 0 ? quantity ~/ piecesPerCarton : 0;

  int get pieceQuantity => piecesPerCarton > 0 ? quantity % piecesPerCarton : quantity;

  double get total => quantity * unitCost;
}
