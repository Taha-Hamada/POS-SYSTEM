import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/data/branches_repository.dart';
import '../../../core/models/branch.dart';
import '../../../core/models/employee.dart';
import '../../../core/models/user_role.dart';
import '../data/employees_repository.dart';
import '../models/employees_sort_column.dart';
import '../models/role_catalog.dart';
import '../widgets/employee_form_dialog.dart';

/// حالة شاشة الموظفين: القائمة والبحث والدور والفرع والفرز.
///
/// الفريق بيتقري كله مرة واحدة والفلترة محلية: العدد صغير، والإحصائيات
/// فوق الجدول لازم تبقى عن الفريق كله مش عن الصفحة المعروضة.
class EmployeesListController extends ChangeNotifier with LoadState {
  EmployeesListController(this._repository, this._branches);

  final EmployeesRepository _repository;
  final BranchesRepository _branches;

  final TextEditingController searchController = TextEditingController();

  List<Employee> _all = <Employee>[];
  Map<String, double> _todaySales = <String, double>{};
  List<Branch> _branchList = <Branch>[];

  /// كتالوج الأدوار والصلاحيات — بيستخدمه حوار صلاحيات الموظف.
  RoleCatalog _catalog = RoleCatalog.empty;

  String _query = '';
  String? _branchId;
  String? _role;
  int _sortIndex = 0;
  bool _sortAscending = true;

  List<Employee>? _cachedRows;

  String? get branchId => _branchId;
  String? get role => _role;
  int get sortIndex => _sortIndex;
  bool get sortAscending => _sortAscending;

  List<Branch> get branches => _branchList;
  RoleCatalog get catalog => _catalog;

  /// باقة صلاحيات دور الموظف، عشان الحوار يعرف الجاي من الدور من الإضافي.
  Set<String> rolePermissionsOf(Employee employee) =>
      _catalog.roles
          .where((RoleInfo r) => r.value == employee.role)
          .map((RoleInfo r) => r.permissions)
          .firstOrNull ??
      <String>{};
  List<Employee> get rows => _cachedRows ??= _computeRows();

  int get visibleCount => rows.length;
  bool get isEmpty => !isLoading && !hasFailed && _all.isEmpty;

  double salesOf(Employee e) => _todaySales[e.id] ?? 0;

  double get visibleTodaySales =>
      rows.fold<double>(0, (double s, Employee e) => s + salesOf(e));

  // ── إحصائيات ─────────────────────────────────────────────────────────────
  int get totalCount => _all.length;

  int get activeCount => _all.where((Employee e) => e.isActive).length;

  double get todaySales =>
      _todaySales.values.fold<double>(0, (double s, double v) => s + v);

  /// رواتب الحسابات الشغالة بس — الموقوف مش بيتقبض.
  double get totalSalaries => _all
      .where((Employee e) => e.isActive)
      .fold<double>(0, (double s, Employee e) => s + e.salary);

  int countForRole(UserRole role) =>
      _all.where((Employee e) => e.role == role.apiValue).length;

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchAll(),
        _repository.fetchTodaySales(),
        if (_branchList.isEmpty)
          _branches.fetchAll()
        else
          Future<List<Branch>>.value(_branchList),
        _repository.fetchCatalog(),
      ]);

      _all = results[0] as List<Employee>;
      _todaySales = results[1] as Map<String, double>;
      _branchList = results[2] as List<Branch>;
      _catalog = results[3] as RoleCatalog;
      _cachedRows = null;
    });
  }

  Future<void> retry() => load();

  // ── الفلترة والفرز ───────────────────────────────────────────────────────
  List<Employee> _computeRows() {
    final String q = _query.trim().toLowerCase();

    final List<Employee> list = _all.where((Employee e) {
      if (_branchId != null && e.branchId != _branchId) return false;
      if (_role != null && e.role != _role) return false;
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q) ||
          e.username.contains(q) ||
          e.roleLabel.contains(q) ||
          e.phone.contains(q);
    }).toList();

    final EmployeesSortColumn column = EmployeesSortColumn.values[_sortIndex];

    list.sort((Employee a, Employee b) {
      final int result = switch (column) {
        EmployeesSortColumn.name => a.name.compareTo(b.name),
        EmployeesSortColumn.role => a.roleLabel.compareTo(b.roleLabel),
        EmployeesSortColumn.branch => (a.branchName ?? '').compareTo(
          b.branchName ?? '',
        ),
        EmployeesSortColumn.status => (a.isActive ? 0 : 1).compareTo(
          b.isActive ? 0 : 1,
        ),
        // اللي عمره ما دخل بيتحسب أقدم من أي حد دخل.
        EmployeesSortColumn.lastLogin =>
          (a.lastLoginAt ?? DateTime(0)).compareTo(
            b.lastLoginAt ?? DateTime(0),
          ),
      };
      return _sortAscending ? result : -result;
    });

    return list;
  }

  void setQuery(String value) {
    _query = value;
    _refresh();
  }

  void setRole(String? value) {
    _role = value;
    _refresh();
  }

  void setBranch(String? id) {
    _branchId = id;
    _refresh();
  }

  void sortBy(int columnIndex, bool ascending) {
    _sortIndex = columnIndex;
    _sortAscending = ascending;
    _refresh();
  }

  void _refresh() {
    _cachedRows = null;
    notifyListeners();
  }

  // ── الكتابة ──────────────────────────────────────────────────────────────
  /// إضافة موظف أو تعديل بياناته. بترجّع رسالة الخطأ لو فشلت.
  Future<String?> save(EmployeeInput input, {Employee? existing}) async {
    final ApiException? failure = await runAction(() async {
      if (existing == null) {
        await _repository.create(
          name: input.name,
          username: input.username,
          password: input.password!,
          role: input.role,
          branchId: input.branchId,
          phone: input.phone,
          email: input.email,
          salary: input.salary,
        );
        return;
      }

      await _repository.update(existing.id, <String, dynamic>{
        'name': input.name,
        'username': input.username,
        'role': input.role,
        'branch': input.branchId,
        'phone': input.phone,
        'email': input.email,
        'salary': input.salary,
      });
    });

    if (failure == null) await load();

    return failure?.message;
  }

  Future<String?> setActive(Employee employee, {required bool isActive}) async {
    final ApiException? failure = await runAction(() async {
      await _repository.setActive(employee.id, isActive: isActive);
    });

    if (failure == null) await load();

    return failure?.message;
  }

  /// بيحفظ صلاحيات الموظف الخاصة. الاستثناءات بتسري فورًا على جلسته
  /// لأن السيرفر بيحسب الصلاحيات مع كل طلب.
  Future<String?> savePermissions(
    Employee employee, {
    required Set<String> granted,
    required Set<String> revoked,
  }) async {
    final ApiException? failure = await runAction(() async {
      await _repository.savePermissions(
        employee.id,
        granted: granted,
        revoked: revoked,
      );
    });

    if (failure == null) await load();

    return failure?.message;
  }

  Future<String?> resetPassword(Employee employee, String password) async {
    final ApiException? failure = await runAction(() async {
      await _repository.resetPassword(employee.id, password);
    });

    return failure?.message;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
