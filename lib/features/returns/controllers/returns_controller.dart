import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/utils/invoice_math.dart';
import '../data/returns_repository.dart';
import '../models/return_line.dart';
import '../models/returnable_invoice.dart';

/// أسباب الإرجاع المتاحة.
const List<String> kReturnReasons = <String>[
  'الصنف تالف',
  'الصنف مش مطابق للطلب',
  'العميل غيّر رأيه',
  'خطأ في الفاتورة',
  'قرب انتهاء الصلاحية',
  'سبب آخر',
];

/// طرق ردّ الفلوس، ومعاها الاسم اللي السيرفر بيفهمه.
const Map<String, String> kRefundMethods = <String, String>{
  'cash': 'كاش',
  'credit': 'على حساب العميل',
};

/// حالة شاشة المرتجعات: الفاتورة المختارة والأصناف المحددة للإرجاع.
class ReturnsController extends ChangeNotifier with LoadState {
  ReturnsController(this._repository);

  final ReturnsRepository _repository;

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  ReturnableInvoice? _invoice;
  List<ReturnLine> _lines = <ReturnLine>[];
  String? _reason;
  String _refundMethod = 'cash';
  String? _error;

  ReturnableInvoice? get invoice => _invoice;
  List<ReturnLine> get lines => _lines;
  String? get reason => _reason;
  String get refundMethod => _refundMethod;
  String? get error => _error;

  bool get hasInvoice => _invoice != null;

  List<ReturnLine> get selectedLines =>
      _lines.where((ReturnLine l) => l.selected).toList(growable: false);

  /// قيمة الـCheckbox في رأس الجدول.
  bool get allSelected =>
      _lines.isNotEmpty && _lines.every((ReturnLine l) => l.selected);

  // ── حسابات الاسترداد ─────────────────────────────────────────────────────
  //
  // نفس خطوات `return.service.js` بالظبط: قيمة السطور بالتناسب، ناقص نصيب
  // المرتجع من خصم الفاتورة، زائد الضريبة المسجّلة على السطور.
  // قبل كده كانت الشاشة بتضرب في نسبة الضريبة وبتتجاهل خصم الفاتورة، فكانت
  // بتعرض للكاشير رقم أعلى من اللي بيترد فعلًا.
  double get refundSubtotal => selectedLines.fold<double>(
        0,
        (double s, ReturnLine l) => s + l.refundAmount,
      );

  double get refundTax => round2(
        selectedLines.fold<double>(0, (double s, ReturnLine l) => s + l.refundTax),
      );

  /// نصيب المرتجع من خصم الفاتورة — بيتخصم من المبلغ المسترد.
  double get refundDiscountShare {
    final ReturnableInvoice? inv = _invoice;
    if (inv == null || inv.invoiceDiscount <= 0 || inv.discountBase <= 0) {
      return 0;
    }

    return round2(
      inv.invoiceDiscount * (round2(refundSubtotal) / inv.discountBase),
    );
  }

  double get refundTotal =>
      round2(round2(refundSubtotal) - refundDiscountShare + refundTax);

  /// الجزء اللي هيتسوّى على حساب العميل مهما كانت طريقة الرد — آجل الفاتورة.
  double get settledOnAccount {
    final ReturnableInvoice? inv = _invoice;
    if (inv == null || inv.creditAmount <= 0 || inv.total <= 0) return 0;

    final double share = round2(inv.creditAmount * (refundTotal / inv.total));
    return share > refundTotal ? refundTotal : share;
  }

  /// اللي هيخرج كاش من الدرج فعلًا.
  double get cashRefund =>
      _refundMethod == 'cash' ? round2(refundTotal - settledOnAccount) : 0;

  double get returnedUnits => selectedLines.fold<double>(
        0,
        (double s, ReturnLine l) => s + l.returnQuantity,
      );

  bool get canSubmit =>
      selectedLines.isNotEmpty &&
      _reason != null &&
      !isLoading &&
      selectedLines.every((ReturnLine l) => l.returnQuantity > 0);

  /// التنبيه اللي بيظهر تحت قائمة الأسباب.
  bool get needsReason => selectedLines.isNotEmpty && _reason == null;

  // ── البحث ────────────────────────────────────────────────────────────────
  Future<void> search([String? value]) async {
    final String query = (value ?? searchController.text).trim();
    if (query.isEmpty) return;

    _error = null;
    notifyListeners();

    final ApiException? failure = await runAction(() async {
      final ReturnableInvoice found = await _repository.findByNumber(query);
      _adopt(found);
    });

    if (failure != null) {
      _invoice = null;
      _lines = <ReturnLine>[];
      _error = failure.isNotFound
          ? 'مفيش فاتورة بالرقم «$query» — جرّب رقم تاني'
          : failure.message;
      notifyListeners();
    }
  }

  void _adopt(ReturnableInvoice found) {
    _invoice = found;
    _reason = null;
    _lines = <ReturnLine>[
      for (final ReturnableLine line in found.lines) ReturnLine(source: line),
    ];

    if (found.isFullyReturned) {
      _error = 'الفاتورة ${found.number} اترجّعت بالكامل قبل كده';
    } else if (!found.isWithinWindow) {
      _error = 'الفاتورة عدّى عليها ${found.ageDays} يوم — '
          'مهلة الإرجاع ${found.windowDays} يوم';
    }
  }

  void clear() {
    _invoice = null;
    _lines = <ReturnLine>[];
    _reason = null;
    _error = null;
    searchController.clear();
    searchFocus.requestFocus();
    notifyListeners();
  }

  // ── إجراءات ──────────────────────────────────────────────────────────────
  void setReason(String? reason) {
    _reason = reason;
    notifyListeners();
  }

  void setRefundMethod(String method) {
    _refundMethod = method;
    notifyListeners();
  }

  void setLineSelected(ReturnLine line, bool selected) {
    line.selected = selected;
    notifyListeners();
  }

  void toggleLine(ReturnLine line) => setLineSelected(line, !line.selected);

  void setAllSelected(bool selected) {
    for (final ReturnLine l in _lines) {
      l.selected = selected;
    }
    notifyListeners();
  }

  void setLineRestock(ReturnLine line, bool restock) {
    line.restock = restock;
    notifyListeners();
  }

  /// مينفعش نرجّع أكتر من المتبقي في السطر.
  /// الكسور مسموحة للأصناف اللي بتتباع بالكيلو أو اللتر.
  void setReturnQuantity(ReturnLine line, double quantity) {
    line.returnQuantity = quantity.clamp(0, line.maxQuantity).toDouble();
    notifyListeners();
  }

  // ── التسجيل ──────────────────────────────────────────────────────────────
  /// بيسجّل المرتجع على السيرفر. بيرجّع المرتجع لو نجح، و`null` لو فشل.
  Future<CompletedReturn?> submit() async {
    final ReturnableInvoice? current = _invoice;
    if (current == null || !canSubmit) return null;

    CompletedReturn? created;

    final ApiException? failure = await runAction(() async {
      created = await _repository.submit(
        invoiceId: current.id,
        refundMethod: _refundMethod,
        reason: _reason,
        lines: <ReturnLineInput>[
          for (final ReturnLine l in selectedLines)
            ReturnLineInput(
              invoiceLineId: l.source.invoiceLineId,
              quantity: l.returnQuantity,
              restock: l.restock,
            ),
        ],
      );
    });

    if (failure != null) {
      _error = failure.message;
      notifyListeners();
      return null;
    }

    // بنعيد قراءة الفاتورة عشان الكميات المتبقية تتحدّث،
    // فالكاشير يقدر يرجّع الباقي من غير ما يدوّر عليها تاني.
    await _reloadInvoice(current.id);

    return created;
  }

  Future<void> _reloadInvoice(String invoiceId) async {
    try {
      _adopt(await _repository.fetchReturnable(invoiceId));
    } on ApiException {
      // الفاتورة اترجّعت بالكامل غالبًا؛ بنفضّي الشاشة.
      _invoice = null;
      _lines = <ReturnLine>[];
    }

    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }
}
