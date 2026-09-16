/// فرع جاي من الـ API.
///
/// الفروع بتظهر في فلاتر أكتر من شاشة (المخزون، المصروفات، المشتريات)،
/// فالموديل مشترك بدل ما كل شاشة تعرّف نسختها.
class Branch {
  const Branch({
    required this.id,
    required this.name,
    this.code = '',
    this.address = '',
    this.phone = '',
    this.isMain = false,
    this.isOpen = true,
    this.isActive = true,
    this.openFrom = '09:00',
    this.openTo = '23:00',
    this.managerId,
    this.managerName,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    // المسؤول بيرجع ككائن لما السيرفر يجيب بياناته، وكمعرّف نص غير كده.
    final dynamic manager = json['manager'];
    final dynamic hours = json['openingHours'];

    return Branch(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isMain: json['isMain'] as bool? ?? false,
      isOpen: json['isOpen'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      openFrom: hours is Map<String, dynamic>
          ? hours['from'] as String? ?? '09:00'
          : '09:00',
      openTo: hours is Map<String, dynamic>
          ? hours['to'] as String? ?? '23:00'
          : '23:00',
      managerId: manager is Map<String, dynamic>
          ? manager['id'] as String?
          : manager as String?,
      managerName: manager is Map<String, dynamic>
          ? manager['name'] as String?
          : null,
    );
  }

  final String id;
  final String name;
  final String code;
  final String address;
  final String phone;

  /// الفرع الرئيسي واحد بس، ومينفعش يتعطّل.
  final bool isMain;

  /// مفتوح دلوقتي ولا لأ — بيتقلب يدويًا من شاشة الفروع.
  final bool isOpen;
  final bool isActive;

  /// مواعيد العمل بصيغة HH:MM زي ما السيرفر بيخزّنها.
  final String openFrom;
  final String openTo;

  final String? managerId;
  final String? managerName;

  String get openingHours => '$openFrom – $openTo';

  @override
  bool operator ==(Object other) => other is Branch && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
