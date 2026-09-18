/// مرتجع متسجّل — لسجل المرتجعات.
class ReturnRecord {
  const ReturnRecord({
    required this.id,
    required this.number,
    required this.total,
    required this.refundMethod,
    required this.createdAt,
    this.invoiceNumber = '',
    this.customerName,
    this.cashierName = '',
    this.branchName = '',
    this.reason = '',
    this.lines = const <ReturnRecordLine>[],
  });

  factory ReturnRecord.fromJson(Map<String, dynamic> json) {
    String? nameOf(dynamic value) =>
        value is Map<String, dynamic> ? value['name'] as String? : null;

    final dynamic invoice = json['invoice'];

    return ReturnRecord(
      id: json['id'] as String? ?? '',
      number: json['number'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      refundMethod: json['refundMethod'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      invoiceNumber: invoice is Map<String, dynamic>
          ? invoice['number'] as String? ?? ''
          : '',
      customerName: nameOf(json['customer']),
      cashierName: nameOf(json['cashier']) ?? '',
      branchName: nameOf(json['branch']) ?? '',
      reason: json['reason'] as String? ?? '',
      lines: (json['lines'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ReturnRecordLine.fromJson)
          .toList(growable: false),
    );
  }

  final String id;
  final String number;
  final double total;

  /// cash / card / wallet / credit
  final String refundMethod;
  final DateTime createdAt;
  final String invoiceNumber;
  final String? customerName;
  final String cashierName;
  final String branchName;
  final String reason;

  /// فاضية في القايمة — بتيجي مع تفاصيل المرتجع بس.
  final List<ReturnRecordLine> lines;

  String get refundMethodLabel => switch (refundMethod) {
    'cash' => 'كاش',
    'credit' => 'من حساب العميل',
    _ => refundMethod,
  };
}

class ReturnRecordLine {
  const ReturnRecordLine({
    required this.name,
    required this.quantity,
    required this.lineTotal,
    this.restock = true,
    this.reason = '',
  });

  factory ReturnRecordLine.fromJson(Map<String, dynamic> json) =>
      ReturnRecordLine(
        name: json['name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
        restock: json['restock'] as bool? ?? true,
        reason: json['reason'] as String? ?? '',
      );

  final String name;
  final double quantity;
  final double lineTotal;

  /// رجع للمخزون سليم ولا اتسجّل تالف.
  final bool restock;
  final String reason;
}
