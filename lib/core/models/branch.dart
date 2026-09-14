/// فرع جاي من الـ API.
///
/// الفروع بتظهر في فلاتر أكتر من شاشة (المخزون، المصروفات، المشتريات)،
/// فالموديل مشترك بدل ما كل شاشة تعرّف نسختها.
class Branch {
  const Branch({required this.id, required this.name, this.code = ''});

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        code: json['code'] as String? ?? '',
      );

  final String id;
  final String name;
  final String code;

  @override
  bool operator ==(Object other) => other is Branch && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
