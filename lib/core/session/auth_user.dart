import '../models/user_role.dart';

/// المستخدم اللي مسجّل دخول دلوقتي، زي ما الباك اند بيرجّعه.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.permissions,
    this.branchId,
    this.branchName,
    this.phone,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    // الفرع بيرجع ككائن كامل بعد الدخول، وكمعرّف نص في ردود تانية.
    final dynamic branch = json['branch'];

    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? '',
      phone: json['phone'] as String?,
      branchId: branch is Map<String, dynamic>
          ? branch['id'] as String?
          : branch as String?,
      branchName: branch is Map<String, dynamic>
          ? branch['name'] as String?
          : null,
      permissions: (json['permissions'] as List<dynamic>? ?? <dynamic>[])
          .cast<String>()
          .toSet(),
    );
  }

  final String id;
  final String name;
  final String username;
  final String role;
  final String? phone;
  final String? branchId;
  final String? branchName;
  final Set<String> permissions;

  bool get isAdmin => role == 'admin';

  /// مدير النظام بيعدّي على كل الفحوصات زي ما الباك اند بيعمل بالظبط.
  bool can(String permission) => isAdmin || permissions.contains(permission);

  bool canAny(List<String> required) =>
      isAdmin || required.any(permissions.contains);

  String get roleLabel => UserRole.labelFor(role);

  String get initials {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}';
  }
}
