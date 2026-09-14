import '../../../core/models/purchase_order.dart';

/// صف استلام — بيحمل الكمية اللي بتتستلم دلوقتي.
class ReceiveLine {
  ReceiveLine({required this.orderLine, double? receivingNow})
      : receivingNow = receivingNow ?? orderLine.remaining;

  final PurchaseOrderLine orderLine;
  double receivingNow;

  double get ordered => orderLine.quantity;
  double get previouslyReceived => orderLine.receivedQuantity;
  double get totalAfter => previouslyReceived + receivingNow;
  double get remainingAfter => ordered - totalAfter;

  double get receivingValue => receivingNow * orderLine.unitCost;

  /// الصفوف اللي مفيش فيها كمية مبتتبعتش — السيرفر بيرفض الكمية صفر.
  bool get isPending => receivingNow > 0;
}
