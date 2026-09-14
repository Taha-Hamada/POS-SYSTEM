/// مورد جاي من الـ API.
class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    this.contactPerson = '',
    this.email = '',
    this.address = '',
    this.taxNumber = '',
    this.balanceDue = 0,
    this.paymentTermDays = 0,
    this.totalPurchases = 0,
    this.ordersCount = 0,
    this.note = '',
    this.isActive = true,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        contactPerson: json['contactPerson'] as String? ?? '',
        email: json['email'] as String? ?? '',
        address: json['address'] as String? ?? '',
        taxNumber: json['taxNumber'] as String? ?? '',
        balanceDue: (json['balanceDue'] as num?)?.toDouble() ?? 0,
        paymentTermDays: (json['paymentTermDays'] as num?)?.toInt() ?? 0,
        totalPurchases: (json['totalPurchases'] as num?)?.toDouble() ?? 0,
        ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
        note: json['note'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
      );

  final String id;
  final String name;
  final String phone;
  final String contactPerson;
  final String email;
  final String address;
  final String taxNumber;

  /// المستحق للمورد علينا. موجب = إحنا مدينين له.
  final double balanceDue;
  final int paymentTermDays;

  /// قيمة الأوامر المكتملة — بيتحدّث على السيرفر وقت اكتمال الاستلام.
  final double totalPurchases;
  final int ordersCount;
  final String note;
  final bool isActive;

  bool get hasDue => balanceDue > 0;

  /// اللي اتسدد فعلًا = قيمة المشتريات ناقص اللي لسه مستحق.
  ///
  /// السيرفر مبيمسكش كشف حساب للموردين، فالرقم ده هو أقرب حقيقة متاحة.
  double get paidAmount {
    final double paid = totalPurchases - balanceDue;
    return paid < 0 ? 0 : paid;
  }

  double get averageOrder =>
      ordersCount == 0 ? 0 : totalPurchases / ordersCount;
}
