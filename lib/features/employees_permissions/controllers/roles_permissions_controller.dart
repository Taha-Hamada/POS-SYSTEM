import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../data/employees_repository.dart';
import '../models/permission_groups.dart';
import '../models/role_catalog.dart';

/// حالة شاشة الأدوار: الدور المختار وصلاحياته وهل فيه تغييرات غير محفوظة.
///
/// التعديلات بتتجمع محليًا لكل دور ومبتتبعتش غير مع «حفظ»، عشان المدير
/// يقدر يقلّب بين الأدوار ويرجع من غير ما يفقد اللي عدّله.
class RolesPermissionsController extends ChangeNotifier with LoadState {
  RolesPermissionsController(
    this._repository, {
    required TickerProvider vsync,
    this.canEdit = false,
  }) {
    fadeController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
  }

  final EmployeesRepository _repository;

  /// المستخدم معندوش إدارة الموظفين، فالشاشة بتبقى للعرض بس.
  final bool canEdit;

  /// أنيميشن الـFade عند تبديل الدور
  late final AnimationController fadeController;

  /// الأدوار الأكثر استخدامًا فوق، ومدير النظام تحت لأنه مبيتعدّلش.
  static const List<String> _order = <String>[
    'cashier',
    'manager',
    'accountant',
    'stock_keeper',
    'admin',
  ];

  RoleCatalog _catalog = RoleCatalog.empty;
  List<RoleInfo> _roles = <RoleInfo>[];
  List<PermissionGroupDef> _groups = <PermissionGroupDef>[];
  final Map<String, Set<String>> _drafts = <String, Set<String>>{};
  String? _selected;

  List<RoleInfo> get roles => _roles;
  List<PermissionGroupDef> get groups => _groups;
  String? get selectedRoleId => _selected;

  RoleInfo? get role {
    for (final RoleInfo r in _roles) {
      if (r.value == _selected) return r;
    }
    return null;
  }

  bool get editable => canEdit && (role?.editable ?? false);

  Set<String> get _current => _drafts[_selected] ?? <String>{};

  int get enabledCount => _current.length;
  int get totalPermissions => _catalog.permissions.length;

  bool isEnabled(String permission) => _current.contains(permission);

  int enabledCountForRole(String roleId) => _drafts[roleId]?.length ?? 0;

  int enabledCountIn(PermissionGroupDef group) => group.permissions
      .where((PermissionDef p) => _current.contains(p.value))
      .length;

  bool isGroupAllOn(PermissionGroupDef group) =>
      enabledCountIn(group) == group.permissions.length;

  bool get dirty => _selected != null && isDirty(_selected!);

  /// الدور ده فيه تعديلات لسه متحفظتش.
  bool isDirty(String roleId) {
    for (final RoleInfo r in _roles) {
      if (r.value == roleId) {
        return !setEquals(_drafts[roleId] ?? <String>{}, r.permissions);
      }
    }
    return false;
  }

  /// فيه حاجة ترجع: تعديلات مش محفوظة، أو باقة متخصّصة على السيرفر.
  bool get canReset => editable && (dirty || (role?.customized ?? false));

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      _apply(await _repository.fetchCatalog());
    });
  }

  Future<void> retry() => load();

  /// [onlyRole] بيحدّث مسودة دور واحد بس، عشان حفظ دور مايمسحش تعديلات
  /// لسه مش محفوظة على دور تاني.
  void _apply(RoleCatalog catalog, {String? onlyRole}) {
    _catalog = catalog;
    _roles = List<RoleInfo>.of(catalog.roles)
      ..sort(
        (RoleInfo a, RoleInfo b) => _rank(a.value).compareTo(_rank(b.value)),
      );
    _groups = permissionGroupsFor(catalog.permissions);

    for (final RoleInfo r in _roles) {
      if (onlyRole == null ||
          r.value == onlyRole ||
          !_drafts.containsKey(r.value)) {
        _drafts[r.value] = Set<String>.of(r.permissions);
      }
    }

    if (_selected == null && _roles.isNotEmpty) _selected = _roles.first.value;
  }

  static int _rank(String role) {
    final int index = _order.indexOf(role);
    return index == -1 ? _order.length : index;
  }

  // ── إجراءات ──────────────────────────────────────────────────────────────
  void selectRole(String roleId) {
    if (roleId == _selected) return;

    _selected = roleId;
    fadeController
      ..reset()
      ..forward();
    notifyListeners();
  }

  void toggle(String permission, bool value) {
    if (!editable) return;

    if (value) {
      _current.add(permission);
    } else {
      _current.remove(permission);
    }
    notifyListeners();
  }

  void toggleGroup(PermissionGroupDef group, bool value) {
    if (!editable) return;

    for (final PermissionDef p in group.permissions) {
      if (value) {
        _current.add(p.value);
      } else {
        _current.remove(p.value);
      }
    }
    notifyListeners();
  }

  /// بيحفظ باقة الدور المختار. بترجّع رسالة الخطأ لو فشل.
  Future<String?> save() async {
    final String? roleId = _selected;
    if (roleId == null || !editable) return null;

    final Set<String> permissions = Set<String>.of(_current);

    final ApiException? failure = await runAction(() async {
      _apply(
        await _repository.saveRolePermissions(roleId, permissions),
        onlyRole: roleId,
      );
    });

    return failure?.message;
  }

  /// بيرجّع الدور لباقته الافتراضية.
  ///
  /// لو الدور متخصّص على السيرفر بنمسح التخصيص هناك، وغير كده
  /// بنلغي التعديلات المحلية بس لأن المحفوظ هو الافتراضي أصلًا.
  Future<String?> resetToDefaults() async {
    final RoleInfo? r = role;
    if (r == null || !editable) return null;

    if (!r.customized) {
      _drafts[r.value] = Set<String>.of(r.permissions);
      notifyListeners();
      return null;
    }

    final ApiException? failure = await runAction(() async {
      _apply(await _repository.resetRole(r.value), onlyRole: r.value);
    });

    return failure?.message;
  }

  @override
  void dispose() {
    fadeController.dispose();
    super.dispose();
  }
}
