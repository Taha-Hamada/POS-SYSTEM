import 'payment_entry.dart';
import '../../../core/models/payment_method.dart';

/// نتيجة عملية الدفع.
class PaymentResult {
  const PaymentResult({
    required this.entries,
    required this.total,
    required this.paid,
    required this.change,
  });

  final List<PaymentEntry> entries;
  final double total;
  final double paid;
  final double change;

  bool get isSplit => entries.length > 1;

  String get methodsLabel =>
      entries.map((PaymentEntry e) => e.method.label).join(' + ');
}
