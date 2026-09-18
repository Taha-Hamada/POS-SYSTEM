/// فاتورة مع الأصناف المتاح إرجاعها منها، زي ما السيرفر بيحسبها.
class ReturnableInvoice {
  const ReturnableInvoice({
    required this.id,
    required this.number,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.ageDays,
    required this.isWithinWindow,
    required this.windowDays,
    required this.lines,
    this.customerName,
    this.subtotal = 0,
    this.lineDiscountTotal = 0,
    this.invoiceDiscount = 0,
    this.creditAmount = 0,
  });

  factory ReturnableInvoice.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> invoice =
        (json['invoice'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final dynamic customer = invoice['customer'];

    return ReturnableInvoice(
      id: invoice['id'] as String? ?? '',
      number: invoice['number'] as String? ?? '',
      total: (invoice['total'] as num?)?.toDouble() ?? 0,
      status: invoice['status'] as String? ?? '',
      createdAt:
          DateTime.tryParse(invoice['createdAt'] as String? ?? '') ??
              DateTime.now(),
      ageDays: (json['ageDays'] as num?)?.toInt() ?? 0,
      isWithinWindow: json['isWithinWindow'] as bool? ?? true,
      windowDays: (json['windowDays'] as num?)?.toInt() ?? 30,
      customerName: customer is Map<String, dynamic>
          ? customer['name'] as String?
          : null,
      subtotal: (invoice['subtotal'] as num?)?.toDouble() ?? 0,
      lineDiscountTotal:
          (invoice['lineDiscountTotal'] as num?)?.toDouble() ?? 0,
      invoiceDiscount: (invoice['invoiceDiscount'] as num?)?.toDouble() ?? 0,
      creditAmount: (invoice['creditAmount'] as num?)?.toDouble() ?? 0,
      lines: (json['lines'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ReturnableLine.fromJson)
          .toList(),
    );
  }

  final String id;
  final String number;
  final double total;
  final String status;
  final DateTime createdAt;

  /// عمر الفاتورة بالأيام.
  final int ageDays;

  /// لسه جوه مهلة الإرجاع ولا عدّاها.
  final bool isWithinWindow;
  final int windowDays;

  final String? customerName;
  final List<ReturnableLine> lines;

  /// أرقام تسعير الفاتورة — الشاشة بتحسب بيها المرتجع بنفس خطوات السيرفر.
  final double subtotal;
  final double lineDiscountTotal;
  final double invoiceDiscount;

  /// الجزء الآجل من الفاتورة — بيتسوّى على حساب العميل مهما كانت طريقة الرد.
  final double creditAmount;

  /// الأساس اللي خصم الفاتورة اتحسب عليه.
  double get discountBase => subtotal - lineDiscountTotal;

  /// مفيش صنف فاضل للإرجاع — الفاتورة اترجّعت بالكامل.
  bool get isFullyReturned => lines.isEmpty;
}

/// سطر متاح إرجاعه، بالكمية المتبقية منه.
class ReturnableLine {
  const ReturnableLine({
    required this.invoiceLineId,
    required this.productId,
    required this.name,
    required this.sku,
    required this.unit,
    required this.soldQuantity,
    required this.returnedQuantity,
    required this.remainingQuantity,
    required this.unitPrice,
    required this.lineTotal,
    this.taxAmount = 0,
  });

  factory ReturnableLine.fromJson(Map<String, dynamic> json) {
    final dynamic product = json['product'];

    return ReturnableLine(
      invoiceLineId: json['invoiceLine'] as String? ?? '',
      productId: product is Map<String, dynamic>
          ? product['id'] as String? ?? ''
          : product as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      soldQuantity: (json['soldQuantity'] as num?)?.toDouble() ?? 0,
      returnedQuantity: (json['returnedQuantity'] as num?)?.toDouble() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  final String invoiceLineId;
  final String productId;
  final String name;
  final String sku;
  final String unit;
  final double soldQuantity;

  /// اترجّع منه قبل كده.
  final double returnedQuantity;

  /// المتاح إرجاعه دلوقتي.
  final double remainingQuantity;

  final double unitPrice;

  /// قيمة السطر بعد خصمه، زي ما اتسجّلت في الفاتورة.
  final double lineTotal;

  /// ضريبة السطر زي ما اتسجّلت في الفاتورة — محسوبة بعد خصم الفاتورة.
  final double taxAmount;

  bool get isPartiallyReturned => returnedQuantity > 0;
}

/// مرتجع اتسجّل.
class CompletedReturn {
  const CompletedReturn({
    required this.id,
    required this.number,
    required this.total,
    required this.taxAmount,
    required this.refundMethod,
    this.cashRefund = 0,
    this.creditRefund = 0,
  });

  factory CompletedReturn.fromJson(Map<String, dynamic> json) =>
      CompletedReturn(
        id: json['id'] as String? ?? '',
        number: json['number'] as String? ?? '',
        total: (json['total'] as num?)?.toDouble() ?? 0,
        taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
        refundMethod: json['refundMethod'] as String? ?? 'cash',
        cashRefund: (json['cashRefund'] as num?)?.toDouble() ?? 0,
        creditRefund: (json['creditRefund'] as num?)?.toDouble() ?? 0,
      );

  final String id;
  final String number;
  final double total;
  final double taxAmount;
  final String refundMethod;

  /// اللي خرج كاش من الدرج فعلًا.
  final double cashRefund;

  /// اللي اتسوّى على حساب العميل.
  final double creditRefund;
}
