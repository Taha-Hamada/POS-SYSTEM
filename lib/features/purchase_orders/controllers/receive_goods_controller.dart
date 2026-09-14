import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/purchase_order.dart';
import '../data/purchases_repository.dart';
import '../models/receive_line.dart';

/// حالة الاستلام: الكمية اللي بتتستلم دلوقتي من كل صنف.
///
/// الاستلام بيزوّد المخزون ويحمّل قيمة البضاعة على حساب المورد على السيرفر،
/// وبيحدّث تكلفة المنتج بالمتوسط المرجح لو [updateCost] مفعّلة.
class ReceiveGoodsController extends ChangeNotifier with LoadState {
  ReceiveGoodsController(this._repository, {required this.order})
      : lines = <ReceiveLine>[
          for (final PurchaseOrderLine l in order.lines)
            ReceiveLine(orderLine: l),
        ];

  final PurchasesRepository _repository;
  final PurchaseOrder order;
  final List<ReceiveLine> lines;

  bool _updateCost = true;
  String? submitError;

  bool get updateCost => _updateCost;

  double get orderedTotal => order.totalQuantity;

  double get receivedTotal =>
      lines.fold<double>(0, (double s, ReceiveLine l) => s + l.totalAfter);

  double get progress =>
      orderedTotal == 0 ? 0 : (receivedTotal / orderedTotal).clamp(0, 1);

  double get receivingValue =>
      lines.fold<double>(0, (double s, ReceiveLine l) => s + l.receivingValue);

  bool get isComplete => receivedTotal >= orderedTotal;

  bool get canSubmit =>
      !isLoading && lines.any((ReceiveLine l) => l.isPending);

  /// مينفعش نستلم أكتر من المتبقي — السيرفر بيرفضها أصلًا.
  void setReceivingNow(ReceiveLine line, double quantity) {
    line.receivingNow = quantity.clamp(0, line.orderLine.remaining);
    notifyListeners();
  }

  void setUpdateCost({required bool value}) {
    _updateCost = value;
    notifyListeners();
  }

  void receiveAll() {
    for (final ReceiveLine l in lines) {
      l.receivingNow = l.orderLine.remaining;
    }
    notifyListeners();
  }

  void clearAll() {
    for (final ReceiveLine l in lines) {
      l.receivingNow = 0;
    }
    notifyListeners();
  }

  /// بيبعت الاستلام. بيرجّع الأمر بعد التحديث، و`null` لو فشل.
  Future<PurchaseOrder?> submit() async {
    submitError = null;

    PurchaseOrder? updated;

    final ApiException? failure = await runAction(() async {
      updated = await _repository.receive(
        order.id,
        updateCost: _updateCost,
        lines: <ReceiptLineInput>[
          for (final ReceiveLine l in lines)
            if (l.isPending)
              (
                orderLineId: l.orderLine.id,
                quantity: l.receivingNow,
                unitCost: l.orderLine.unitCost,
              ),
        ],
      );
    });

    if (failure != null) {
      submitError = failure.message;
      notifyListeners();
      return null;
    }

    return updated;
  }
}
