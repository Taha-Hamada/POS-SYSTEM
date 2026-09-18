/// عميل جاي من الـ API.
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.balance = 0,
    this.totalPurchases = 0,
    this.ordersCount = 0,
    this.lastVisitAt,
    this.isActive = true,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String?,
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
    totalPurchases: (json['totalPurchases'] as num?)?.toDouble() ?? 0,
    ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
    lastVisitAt: json['lastVisitAt'] == null
        ? null
        : DateTime.tryParse(json['lastVisitAt'] as String),
    isActive: json['isActive'] as bool? ?? true,
  );

  /// العميل العابر — بيع نقدي من غير حساب. مالوش وجود على السيرفر،
  /// فالفاتورة بتتبعت من غير عميل أصلًا.
  const Customer.walkIn()
    : id = '',
      name = 'عميل عابر',
      phone = '',
      email = null,
      balance = 0,
      totalPurchases = 0,
      ordersCount = 0,
      lastVisitAt = null,
      isActive = true;

  final String id;
  final String name;
  final String phone;
  final String? email;

  /// موجب = ليه فلوس عندنا، سالب = عليه فلوس آجل.
  final double balance;
  final double totalPurchases;
  final int ordersCount;
  final DateTime? lastVisitAt;
  final bool isActive;

  bool get isWalkIn => id.isEmpty;

  bool get hasDebt => balance < 0;

  double get debt => balance < 0 ? -balance : 0;

  String get initials {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}';
  }
}
