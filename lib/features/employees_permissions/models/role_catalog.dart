import '../../../core/models/user_role.dart';

/// دور بصلاحياته الحالية والافتراضية زي ما السيرفر شايفها.
class RoleInfo {
  const RoleInfo({
    required this.value,
    required this.label,
    required this.permissions,
    required this.defaultPermissions,
    this.customized = false,
    this.editable = true,
    this.usersCount = 0,
  });

  factory RoleInfo.fromJson(Map<String, dynamic> json) => RoleInfo(
    value: json['value'] as String? ?? '',
    label: json['label'] as String? ?? '',
    permissions: _strings(json['permissions']),
    defaultPermissions: _strings(json['defaultPermissions']),
    customized: json['customized'] as bool? ?? false,
    editable: json['editable'] as bool? ?? true,
    usersCount: (json['usersCount'] as num?)?.toInt() ?? 0,
  );

  static Set<String> _strings(dynamic value) =>
      value is List<dynamic> ? value.whereType<String>().toSet() : <String>{};

  final String value;
  final String label;
  final Set<String> permissions;
  final Set<String> defaultPermissions;

  /// المدير عدّل الباقة ومبقتش زي الافتراضي.
  final bool customized;

  /// مدير النظام بياخد كل الصلاحيات دايمًا ومينفعش يتعدّل.
  final bool editable;
  final int usersCount;

  UserRole? get role => UserRole.fromApi(value);
}

/// كل الأدوار وكل الصلاحيات اللي السيرفر بيعرفها.
class RoleCatalog {
  const RoleCatalog({required this.roles, required this.permissions});

  factory RoleCatalog.fromJson(Map<String, dynamic> json) => RoleCatalog(
    roles: (json['roles'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(RoleInfo.fromJson)
        .toList(growable: false),
    permissions: (json['permissions'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> p) => p['value'] as String? ?? '')
        .where((String p) => p.isNotEmpty)
        .toList(growable: false),
  );

  static const RoleCatalog empty = RoleCatalog(
    roles: <RoleInfo>[],
    permissions: <String>[],
  );

  final List<RoleInfo> roles;
  final List<String> permissions;
}
