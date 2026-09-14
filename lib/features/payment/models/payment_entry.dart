import '../../../core/models/payment_method.dart';

/// دفعة واحدة داخل الفاتورة (الفاتورة ممكن يكون فيها أكتر من واحدة).
class PaymentEntry {
  const PaymentEntry({required this.method, required this.amount});

  final PaymentMethod method;
  final double amount;
}
