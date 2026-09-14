export '../../../core/models/ledger_entry.dart';

/// حركة نقط ولاء.
class LoyaltyEntry {
  const LoyaltyEntry({
    required this.id,
    required this.type,
    required this.points,
    required this.balanceAfter,
    required this.createdAt,
    this.valueAmount = 0,
    this.note = '',
  });

  factory LoyaltyEntry.fromJson(Map<String, dynamic> json) => LoyaltyEntry(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        points: (json['points'] as num?)?.toInt() ?? 0,
        balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        valueAmount: (json['valueAmount'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String? ?? '',
      );

  final String id;

  /// earn أو redeem أو adjust.
  final String type;

  /// موجب = كسب، سالب = استبدال أو سحب.
  final int points;
  final int balanceAfter;
  final DateTime createdAt;

  /// قيمة الاستبدال بالعملة — للاستبدال بس.
  final double valueAmount;
  final String note;

  DateTime get date => createdAt;

  bool get isEarn => points > 0;

  String get typeLabel => switch (type) {
        'earn' => 'كسب',
        'redeem' => 'استبدال',
        'adjust' => 'تسوية',
        _ => type,
      };
}

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
