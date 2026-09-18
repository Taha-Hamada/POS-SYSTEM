/// فاتورة متسجّلة — لسجل الفواتير وتفاصيلها.
class InvoiceRecord {
  const InvoiceRecord({
    required this.id,
    required this.number,
    required this.status,
    required this.total,
    required this.createdAt,
    this.subtotal = 0,
    this.discountTotal = 0,
    this.taxAmount = 0,
    this.paidAmount = 0,
    this.creditAmount = 0,
    this.changeDue = 0,
    this.returnedTotal = 0,
    this.customerName,
    this.cashierName = '',
    this.branchName = '',
    this.voidReason = '',
    this.voidedAt,
    this.payments = const <InvoicePayment>[],
    this.lines = const <InvoiceRecordLine>[],
  });

  factory InvoiceRecord.fromJson(Map<String, dynamic> json) {
    String? nameOf(dynamic value) =>
        value is Map<String, dynamic> ? value['name'] as String? : null;

    DateTime? dateOf(dynamic value) =>
        value is String ? DateTime.tryParse(value)?.toLocal() : null;

    return InvoiceRecord(
      id: json['id'] as String? ?? '',
      number: json['number'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      total: _num(json['total']),
      createdAt: dateOf(json['createdAt']) ?? DateTime.now(),
      subtotal: _num(json['subtotal']),
      discountTotal:
          _num(json['lineDiscountTotal']) + _num(json['invoiceDiscount']),
      taxAmount: _num(json['taxAmount']),
      paidAmount: _num(json['paidAmount']),
      creditAmount: _num(json['creditAmount']),
      changeDue: _num(json['changeDue']),
      returnedTotal: _num(json['returnedTotal']),
      customerName: nameOf(json['customer']),
      cashierName: nameOf(json['cashier']) ?? '',
      branchName: nameOf(json['branch']) ?? '',
      voidReason: json['voidReason'] as String? ?? '',
      voidedAt: dateOf(json['voidedAt']),
      payments: (json['payments'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(InvoicePayment.fromJson)
          .toList(growable: false),
      lines: (json['lines'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(InvoiceRecordLine.fromJson)
          .toList(growable: false),
    );
  }

  static double _num(dynamic value) => (value as num?)?.toDouble() ?? 0;

  final String id;
  final String number;

  /// completed / partially_returned / returned / voided
  final String status;
  final double total;
  final DateTime createdAt;
  final double subtotal;
  final double discountTotal;
  final double taxAmount;
  final double paidAmount;
  final double creditAmount;
  final double changeDue;
  final double returnedTotal;
  final String? customerName;
  final String cashierName;
  final String branchName;
  final String voidReason;
  final DateTime? voidedAt;
  final List<InvoicePayment> payments;

  /// فاضية في القايمة — بتيجي مع تفاصيل الفاتورة بس.
  final List<InvoiceRecordLine> lines;

  bool get isVoided => status == 'voided';

  /// السيرفر بيرفض إلغاء الفاتورة اللي عليها مرتجعات، فالزرار مبيظهرش ليها.
  bool get canVoid => status == 'completed' && returnedTotal == 0;

  String get statusLabel => invoiceStatusLabel(status);

  /// طرق الدفع في سطر واحد: «كاش + بطاقة».
  String get paymentsLabel => payments.isEmpty
      ? '—'
      : payments.map((InvoicePayment p) => p.methodLabel).toSet().join(' + ');
}

String invoiceStatusLabel(String status) => switch (status) {
  'completed' => 'مكتملة',
  'partially_returned' => 'مرتجع جزئي',
  'returned' => 'مرتجعة',
  'voided' => 'ملغاة',
  _ => status,
};

class InvoicePayment {
  const InvoicePayment({required this.method, required this.amount});

  factory InvoicePayment.fromJson(Map<String, dynamic> json) => InvoicePayment(
    method: json['method'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
  );

  final String method;
  final double amount;

  String get methodLabel => switch (method) {
    'cash' => 'كاش',
    'credit' => 'آجل',
    _ => method,
  };
}

class InvoiceRecordLine {
  const InvoiceRecordLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.returnedQuantity = 0,
    this.promotionName = '',
  });

  factory InvoiceRecordLine.fromJson(Map<String, dynamic> json) =>
      InvoiceRecordLine(
        name: json['name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
        returnedQuantity: (json['returnedQuantity'] as num?)?.toDouble() ?? 0,
        promotionName: json['promotionName'] as String? ?? '',
      );

  final String name;
  final double quantity;
  final double unitPrice;

  /// بعد الخصم وقبل الضريبة.
  final double lineTotal;
  final double returnedQuantity;
  final String promotionName;
}
