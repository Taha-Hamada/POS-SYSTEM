import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../core/widgets/numpad.dart';
import '../models/payment_entry.dart';
import '../../../core/models/payment_method.dart';
import '../models/payment_result.dart';

/// حالة شاشة الدفع: الدفعات المسجّلة، الطريقة الحالية، والمبلغ اللي بيتكتب.
class PaymentController extends ChangeNotifier {
  PaymentController({required this.total})
      : _entry = AmountEntry(initial: total) {
    amountController = TextEditingController(text: _entry.text);
  }

  /// إجمالي الفاتورة المطلوب تحصيله.
  final double total;

  final List<PaymentEntry> _entries = <PaymentEntry>[];
  PaymentMethod _method = PaymentMethod.cash;

  /// المبلغ اللي بيتكتب دلوقتي — على الـNumpad أو من الكيبورد.
  final AmountEntry _entry;

  /// نفس المبلغ بس كـTextEditingController عشان الكاشير يقدر يكتبه بإيده.
  late final TextEditingController amountController;

  /// بيزامن الخانة مع الـNumpad بعد أي تعديل جاي من الأزرار.
  void _syncText() {
    if (amountController.text == _entry.text) return;
    amountController.value = TextEditingValue(
      text: _entry.text,
      selection: TextSelection.collapsed(offset: _entry.text.length),
    );
  }

  /// بيتنده لما الكاشير يكتب في الخانة بنفسه.
  void amountTyped(String value) {
    _entry.text = value;
    _entry.fresh = false;
    notifyListeners();
  }

  UnmodifiableListView<PaymentEntry> get entries =>
      UnmodifiableListView<PaymentEntry>(_entries);

  PaymentMethod get method => _method;

  String get amountText => _entry.isEmpty ? '0' : _entry.text;

  // ── حسابات ───────────────────────────────────────────────────────────────
  double get committed =>
      _entries.fold<double>(0, (double s, PaymentEntry e) => s + e.amount);

  /// المتبقي قبل المبلغ اللي بيتكتب دلوقتي
  double get remainingBefore => total - committed;

  double get currentAmount => _entry.value;

  double get paid => committed + currentAmount;

  /// موجب = لسه فاضل، سالب = الباقي للعميل
  double get remainingAfter => total - paid;

  /// الباقي بيطلع من درج الكاش بس — الفيزا والمحفظة والآجل بتتخصم بالمبلغ
  /// اللي اتكتب بالظبط، والسيرفر بيرفض أي زيادة فيهم.
  double get change => remainingAfter < 0 ? -remainingAfter : 0;

  double get _nonCashPaid {
    final double committedNonCash = _entries
        .where((PaymentEntry e) => e.method != PaymentMethod.cash)
        .fold<double>(0, (double s, PaymentEntry e) => s + e.amount);

    return committedNonCash +
        (_method == PaymentMethod.cash ? 0 : currentAmount);
  }

  /// زيادة مش من الكاش — الفاتورة مش هتعدّي بيها.
  double get nonCashOverpay {
    final double over = _nonCashPaid - total;
    return over > 0.005 ? over : 0;
  }

  bool get isCovered => remainingAfter <= 0.005 && nonCashOverpay == 0;

  bool get canSplit =>
      currentAmount > 0 && remainingAfter > 0.005 && _entries.length < 3;

  bool isUsed(PaymentMethod method) =>
      _entries.any((PaymentEntry e) => e.method == method);

  // ── إجراءات ──────────────────────────────────────────────────────────────
  void tapKey(String key) {
    _entry.tapKey(key);
    _syncText();
    notifyListeners();
  }

  void backspace() {
    _entry.backspace();
    _syncText();
    notifyListeners();
  }

  void clearInput() {
    _entry.clear();
    _syncText();
    notifyListeners();
  }

  void addQuick(double value) {
    _entry.add(value);
    _syncText();
    notifyListeners();
  }

  void setExact() {
    _entry.setValue(remainingBefore);
    _syncText();
    notifyListeners();
  }

  void selectMethod(PaymentMethod method) {
    _method = method;
    // الآجل بياخد المتبقي كله على حساب العميل
    if (method == PaymentMethod.credit) {
      _entry.setValue(remainingBefore);
      _syncText();
    }
    notifyListeners();
  }

  /// أقصى مبلغ مسموح للطريقة الحالية — الكاش بس هو اللي بيزيد عن المتبقي.
  double get maxForCurrentMethod =>
      _method == PaymentMethod.cash ? double.infinity : remainingBefore;

  /// يثبّت المبلغ الحالي كدفعة ويفتح دفعة جديدة بالمتبقي.
  void addAnotherMethod() {
    final double amount = currentAmount.clamp(0, remainingBefore);
    if (amount <= 0) return;

    _entries.add(PaymentEntry(method: _method, amount: amount));
    _method = _nextUnusedMethod();
    _entry.setValue(remainingBefore);
    _syncText();
    notifyListeners();
  }

  void removeEntry(int index) {
    _entries.removeAt(index);
    _entry.setValue(remainingBefore);
    _syncText();
    notifyListeners();
  }

  PaymentMethod _nextUnusedMethod() {
    final Set<PaymentMethod> used =
        _entries.map((PaymentEntry e) => e.method).toSet();
    for (final PaymentMethod m in PaymentMethod.values) {
      if (!used.contains(m)) return m;
    }
    return PaymentMethod.cash;
  }

  /// النتيجة النهائية — المبلغ اللي على الشاشة بيتحسب كدفعة أخيرة.
  PaymentResult buildResult() {
    return PaymentResult(
      entries: <PaymentEntry>[
        ..._entries,
        if (currentAmount > 0)
          PaymentEntry(method: _method, amount: currentAmount),
      ],
      total: total,
      paid: paid,
      change: change,
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }
}
