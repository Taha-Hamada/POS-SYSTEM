import '../widgets/status_badge.dart';
import 'payment_method.dart';

/// حالة المصروف على السيرفر.
enum ExpenseStatus { pending, approved, rejected }

extension ExpenseStatusInfo on ExpenseStatus {
  String get apiValue => switch (this) {
        ExpenseStatus.pending => 'pending',
        ExpenseStatus.approved => 'approved',
        ExpenseStatus.rejected => 'rejected',
      };

  String get label => switch (this) {
        ExpenseStatus.pending => 'بانتظار الاعتماد',
        ExpenseStatus.approved => 'معتمد',
        ExpenseStatus.rejected => 'مرفوض',
      };

  StatusTone get tone => switch (this) {
        ExpenseStatus.pending => StatusTone.warning,
        ExpenseStatus.approved => StatusTone.success,
        ExpenseStatus.rejected => StatusTone.danger,
      };
}

ExpenseStatus expenseStatusFromApi(String? value) => ExpenseStatus.values
        .where((ExpenseStatus s) => s.apiValue == value)
        .firstOrNull ??
    ExpenseStatus.pending;

/// مصروف تشغيلي جاي من الـ API.
class Expense {
  const Expense({
    required this.id,
    required this.number,
    required this.date,
    required this.category,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.branchId = '',
    this.branchName = '',
    this.note = '',
    this.createdBy = '',
    this.reviewedBy = '',
    this.rejectionReason = '',
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    // الفرع والمستخدمين بيرجعوا ككائنات لما الاستعلام يعمل populate.
    final dynamic branch = json['branch'];

    return Expense(
      id: json['id'] as String? ?? '',
      number: json['number'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      category: json['category'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: expenseStatusFromApi(json['status'] as String?),
      paymentMethod: paymentMethodFromApi(json['paymentMethod'] as String?),
      branchId: branch is Map<String, dynamic>
          ? branch['id'] as String? ?? ''
          : branch as String? ?? '',
      branchName:
          branch is Map<String, dynamic> ? branch['name'] as String? ?? '' : '',
      note: json['note'] as String? ?? '',
      createdBy: _personName(json['createdBy']),
      reviewedBy: _personName(json['reviewedBy']),
      rejectionReason: json['rejectionReason'] as String? ?? '',
    );
  }

  static String _personName(dynamic value) =>
      value is Map<String, dynamic> ? value['name'] as String? ?? '' : '';

  final String id;

  /// الرقم المعروض للمستخدم (EXP-00042) — غير معرّف الداتابيز.
  final String number;
  final DateTime date;
  final String category;
  final double amount;
  final ExpenseStatus status;
  final PaymentMethod paymentMethod;
  final String branchId;
  final String branchName;
  final String note;
  final String createdBy;
  final String reviewedBy;
  final String rejectionReason;

  bool get isPending => status == ExpenseStatus.pending;

  /// المعتمد اتقفل عليه الحساب، فالسيرفر بيرفض تعديله أو مسحه.
  bool get isLocked => status == ExpenseStatus.approved;
}
