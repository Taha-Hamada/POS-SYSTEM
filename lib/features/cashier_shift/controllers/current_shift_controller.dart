import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/shift.dart';
import '../data/shift_repository.dart';

/// وردية الكاشير المفتوحة، على مستوى التطبيق كله.
///
/// الشريط الجانبي بيعرض حالتها، وشاشة البيع محتاجة تعرف إنها مفتوحة قبل ما تبيع،
/// فبتتحفظ في مكان واحد بدل ما كل شاشة تسأل السيرفر لوحدها.
class CurrentShiftController extends ChangeNotifier with LoadState {
  CurrentShiftController(this._repository, {this.branchId});

  final ShiftRepository _repository;
  final String? branchId;

  Shift? _shift;
  ShiftTotals _totals = const ShiftTotals();

  /// آخر وردية اتقفلت في الجلسة دي — الشاشة بتعرض ملخصها بعد الإغلاق.
  Shift? _lastClosed;

  Shift? get shift => _shift;
  ShiftTotals get totals => _totals;
  Shift? get lastClosed => _lastClosed;

  bool get isOpen => _shift != null;

  /// الرصيد الافتتاحي للوردية المفتوحة، أو صفر لو مفيش.
  double get openingBalance => _shift?.openingBalance ?? 0;

  Future<void> load() async {
    await runLoad(() async {
      final ShiftSnapshot? snapshot = await _repository.fetchCurrent();
      _apply(snapshot);
    });
  }

  Future<void> retry() => load();

  /// بيعيد قراءة الأرقام من السيرفر — بعد بيعة أو مرتجع.
  Future<void> refreshTotals() async {
    final String? id = _shift?.id;
    if (id == null) return;

    try {
      _apply(await _repository.fetchById(id));
    } on ApiException {
      // الأرقام هتفضل قديمة شوية؛ مش سبب لتعطيل الشاشة.
    }
  }

  /// بيفتح وردية. بيرجّع رسالة الخطأ لو فشل، و`null` لو نجح.
  ///
  /// [branchId] بيتبعت للحساب اللي مش مربوط بفرع، وإلا بيتاخد فرع المستخدم.
  Future<String?> open(double openingBalance, {String? branchId}) async {
    final ApiException? failure = await runAction(() async {
      _apply(
        await _repository.open(
          openingBalance: openingBalance,
          branchId: branchId ?? this.branchId,
        ),
      );
    });

    return failure?.message;
  }

  /// بيقفل الوردية ويحتفظ بملخصها عشان الشاشة تعرض الفرق.
  Future<String?> close({required double countedCash, String? note}) async {
    final String? id = _shift?.id;
    if (id == null) return 'مفيش وردية مفتوحة';

    final ApiException? failure = await runAction(() async {
      _lastClosed = await _repository.close(
        id,
        countedCash: countedCash,
        note: note,
      );

      _shift = null;
      _totals = const ShiftTotals();
    });

    return failure?.message;
  }

  Future<String?> addCash({
    required bool isIn,
    required double amount,
    required String reason,
  }) async {
    final String? id = _shift?.id;
    if (id == null) return 'مفيش وردية مفتوحة';

    final ApiException? failure = await runAction(() async {
      await _repository.addCashMovement(
        id,
        isIn: isIn,
        amount: amount,
        reason: reason,
      );

      // الإيداع والسحب بيغيّروا الكاش المتوقع، فبنعيد قراءته من السيرفر
      // بدل ما نحسبه هنا ونفتح باب اختلاف بين الشاشة والدرج.
      _apply(await _repository.fetchById(id));
    });

    return failure?.message;
  }

  void _apply(ShiftSnapshot? snapshot) {
    _shift = snapshot?.shift;
    _totals = snapshot?.totals ?? const ShiftTotals();
  }
}
