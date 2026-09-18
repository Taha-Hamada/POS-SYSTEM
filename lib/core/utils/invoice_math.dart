/// حساب إجماليات الفاتورة على الجهاز.
///
/// السيرفر هو المرجع وقت الاعتماد، بس الكاشير لازم يشوف نفس الرقم قبل ما يدفع،
/// فالحسبة هنا بتطابق `invoice.pricing.js` في الباك اند خطوة بخطوة:
/// خصم السطر، بعدين خصم الفاتورة، وآخر حاجة الضريبة على الأصناف الخاضعة بس،
/// مع توزيع خصم الفاتورة على الوعاء الضريبي بالتناسب.
library;

double round2(double value) => (value * 100).roundToDouble() / 100;

/// سطر جاهز للحساب — مجرّد من أي تفاصيل واجهة.
class PricedLine {
  const PricedLine({
    required this.unitPrice,
    required this.quantity,
    required this.isTaxable,
    this.discountAmount = 0,
  });

  final double unitPrice;
  final int quantity;
  final bool isTaxable;

  /// خصم السطر بالجنيه، محسوب قبل ما يوصل هنا.
  final double discountAmount;

  double get gross => round2(unitPrice * quantity);

  double get lineTotal => round2(gross - discountAmount);
}

class InvoiceTotals {
  const InvoiceTotals({
    required this.subtotal,
    required this.lineDiscountTotal,
    required this.invoiceDiscount,
    required this.taxableBase,
    required this.taxAmount,
    required this.total,
    this.manualDiscount = 0,
  });

  final double subtotal;

  /// خصومات السطور — في الكاشير دي خصومات العروض.
  final double lineDiscountTotal;

  /// الخصم اللي الكاشير حطه — هو كل خصم الفاتورة.
  final double manualDiscount;

  final double invoiceDiscount;
  final double taxableBase;
  final double taxAmount;
  final double total;

  /// كل الخصومات مع بعض — ده اللي الكاشير بيشوفه في ملخص الفاتورة.
  double get discountTotal => round2(lineDiscountTotal + invoiceDiscount);
}

/// خصم الفاتورة اليدوي بيتحسب على الصافي بعد خصومات السطور — بنسبة
/// [invoiceDiscountPercent] أو بمبلغ [invoiceDiscount].
InvoiceTotals calculateTotals({
  required List<PricedLine> lines,
  required double taxRate,
  double invoiceDiscount = 0,
  double invoiceDiscountPercent = 0,
}) {
  final double subtotal = round2(
    lines.fold<double>(0, (double s, PricedLine l) => s + l.gross),
  );

  final double lineDiscountTotal = round2(
    lines.fold<double>(0, (double s, PricedLine l) => s + l.discountAmount),
  );

  final double afterLineDiscounts = round2(subtotal - lineDiscountTotal);

  // الخصم مبيعديش المبلغ اللي بيتحسب عليه ومبيبقاش سالب.
  final double requestedManual = invoiceDiscountPercent > 0
      ? afterLineDiscounts * invoiceDiscountPercent / 100
      : invoiceDiscount;

  final double discount = round2(
    requestedManual.clamp(0, afterLineDiscounts).toDouble(),
  );

  final double taxableAfterLine = round2(
    lines
        .where((PricedLine l) => l.isTaxable)
        .fold<double>(0, (double s, PricedLine l) => s + l.lineTotal),
  );

  // نصيب الأصناف الخاضعة من الصافي، عشان الخصم يقلّل الوعاء بنفس النسبة.
  final double taxableShare = afterLineDiscounts > 0
      ? taxableAfterLine / afterLineDiscounts
      : 0;

  final double taxableBase = round2(taxableAfterLine - discount * taxableShare);
  final double taxAmount = round2(taxableBase * taxRate);

  return InvoiceTotals(
    subtotal: subtotal,
    lineDiscountTotal: lineDiscountTotal,
    manualDiscount: discount,
    invoiceDiscount: discount,
    taxableBase: taxableBase,
    taxAmount: taxAmount,
    total: round2(afterLineDiscounts - discount + taxAmount),
  );
}
