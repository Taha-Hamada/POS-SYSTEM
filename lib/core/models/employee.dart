import 'user_role.dart';

/// موظف (حساب مستخدم) جاي من الـ API.
class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.email,
    this.phone = '',
    this.branchId,
    this.branchName,
    this.salary = 0,
    this.hiredAt,
    this.isActive = true,
    this.lastLoginAt,
    this.grantedPermissions = const <String>{},
    this.revokedPermissions = const <String>{},
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    // الفرع بيرجع ككائن في القوايم، وكمعرّف نص بعد بعض عمليات التعديل.
    final dynamic branch = json['branch'];

    return Employee(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String? ?? '',
      branchId: branch is Map<String, dynamic>
          ? branch['id'] as String?
          : branch as String?,
      branchName: branch is Map<String, dynamic>
          ? branch['name'] as String?
          : null,
      salary: (json['salary'] as num?)?.toDouble() ?? 0,
      hiredAt: DateTime.tryParse(json['hiredAt'] as String? ?? '')?.toLocal(),
      isActive: json['isActive'] as bool? ?? true,
      lastLoginAt: DateTime.tryParse(
        json['lastLoginAt'] as String? ?? '',
      )?.toLocal(),
      grantedPermissions: _strings(json['grantedPermissions']),
      revokedPermissions: _strings(json['revokedPermissions']),
    );
  }

  static Set<String> _strings(dynamic value) => value is List<dynamic>
      ? value.whereType<String>().toSet()
      : const <String>{};

  final String id;
  final String name;
  final String username;

  /// قيمة الدور زي ما السيرفر بيبعتها (admin، cashier…).
  final String role;
  final String? email;
  final String phone;
  final String? branchId;
  final String? branchName;
  final double salary;
  final DateTime? hiredAt;
  final bool isActive;

  /// null معناها إن الحساب عمره ما دخل.
  final DateTime? lastLoginAt;

  /// صلاحيات فوق باقة الدور، واستثناءات بتتشال منها.
  final Set<String> grantedPermissions;
  final Set<String> revokedPermissions;

  UserRole? get userRole => UserRole.fromApi(role);
  String get roleLabel => UserRole.labelFor(role);
  bool get isAdmin => role == UserRole.admin.apiValue;

  String get initials {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}';
  }
}
