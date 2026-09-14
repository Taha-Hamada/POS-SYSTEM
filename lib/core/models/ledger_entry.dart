import 'package:flutter/material.dart';

/// حركة على حساب عميل أو مورد — سطر في كشف الحساب.
///
/// مشترك بين الاتنين لأن الجدول الزمني واحد، وشكل الحركة نفسه في الحالتين.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
    this.note = '',
    this.branchName,
    this.performedBy,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    final dynamic branch = json['branch'];
    final dynamic user = json['performedBy'];

    return LedgerEntry(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String? ?? '',
      branchName:
          branch is Map<String, dynamic> ? branch['name'] as String? : null,
      performedBy: user is Map<String, dynamic> ? user['name'] as String? : null,
    );
  }

  final String id;

  /// sale أو payment أو refund أو adjustment.
  final String type;

  /// موجب = رصيد العميل زاد، سالب = قلّ.
  final double amount;
  final double balanceAfter;
  final DateTime createdAt;
  final String note;
  final String? branchName;
  final String? performedBy;

  /// السداد والمرتجع بيرفعوا الرصيد، والبيع الآجل بينزّله.
  bool get isDebit => amount >= 0;

  DateTime get date => createdAt;

  /// وصف الحركة المعروض تحت عنوانها.
  String get description {
    if (note.isNotEmpty) return note;
    return branchName == null ? typeLabel : '$typeLabel • $branchName';
  }

  String get typeLabel => switch (type) {
        'sale' => 'بيع آجل',
        'payment' => 'سداد',
        'refund' => 'مرتجع',
        'adjustment' => 'تسوية',
        _ => type,
      };

  IconData get icon => switch (type) {
        'sale' => Icons.shopping_bag_outlined,
        'payment' => Icons.payments_outlined,
        'refund' => Icons.undo_rounded,
        'adjustment' => Icons.tune_rounded,
        _ => Icons.receipt_long_outlined,
      };
}
