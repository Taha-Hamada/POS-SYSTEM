export '../../../core/models/ledger_entry.dart';

/// فاتورة في سجل مشتريات العميل.
class CustomerInvoice {
  const CustomerInvoice({
    required this.id,
    required this.number,
    required this.total,
    required this.createdAt,
    required this.status,
    this.itemsCount = 0,
    this.paymentMethods = const <String>[],
  });

  factory CustomerInvoice.fromJson(Map<String, dynamic> json) {
    final List<dynamic> payments =
        json['payments'] as List<dynamic>? ?? <dynamic>[];

    return CustomerInvoice(
      id: json['id'] as String? ?? '',
      number: json['number'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? '',
      itemsCount: (json['itemsCount'] as num?)?.toInt() ?? 0,
      paymentMethods: payments
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> p) => p['method'] as String? ?? '')
          .where((String m) => m.isNotEmpty)
          .toList(),
    );
  }

  final String id;
  final String number;
  final double total;
  final DateTime createdAt;
  final String status;
  final int itemsCount;
  final List<String> paymentMethods;

  bool get isVoided => status == 'voided';
  bool get hasReturns =>
      status == 'returned' || status == 'partially_returned';

  /// طريقة الدفع الأساسية — الأولى في القايمة.
  String get primaryMethod =>
      paymentMethods.isEmpty ? 'cash' : paymentMethods.first;
}
