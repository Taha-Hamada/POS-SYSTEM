import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/employee.dart';
import '../models/role_catalog.dart';

/// قراءة وكتابة الموظفين والأدوار من الـ API.
class EmployeesRepository {
  const EmployeesRepository(this._api);

  final ApiClient _api;

  /// كل الموظفين المطابقين.
  ///
  /// السيرفر بيقفل الصفحة على 100، والفريق نادرًا ما يعدّي كده،
  /// فبنلف على الصفحات بدل ما الجدول يقطع من غير ما حد ياخد باله.
  Future<List<Employee>> fetchAll({
    String? role,
    String? branchId,
    bool? isActive,
  }) async {
    final List<Employee> all = <Employee>[];
    int page = 1;

    while (true) {
      final ApiResponse response = await _api.get(
        '/users',
        query: <String, dynamic>{
          'page': page,
          'limit': 100,
          'sort': 'name',
          'role': role,
          'branch': branchId,
          'isActive': isActive?.toString(),
        },
      );

      all.addAll(response.list.map(Employee.fromJson));
      if (!response.hasNext) break;
      page++;
    }

    return all;
  }

  Future<Employee> create({
    required String name,
    required String username,
    required String password,
    required String role,
    String? branchId,
    String? phone,
    String? email,
    double? salary,
  }) async {
    final ApiResponse response = await _api.post(
      '/users',
      body: <String, dynamic>{
        'name': name,
        'username': username,
        'password': password,
        'role': role,
        'branch': branchId,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'salary': ?salary,
      },
    );

    return Employee.fromJson(response.object);
  }

  Future<Employee> update(String id, Map<String, dynamic> changes) async {
    final ApiResponse response = await _api.patch('/users/$id', body: changes);
    return Employee.fromJson(response.object);
  }

  /// التعطيل بيقفل كل جلسات الموظف فورًا على السيرفر.
  Future<Employee> setActive(String id, {required bool isActive}) async {
    final ApiResponse response = await _api.patch(
      '/users/$id/active',
      body: <String, bool>{'isActive': isActive},
    );
    return Employee.fromJson(response.object);
  }

  Future<void> resetPassword(String id, String newPassword) => _api.patch(
    '/users/$id/password',
    body: <String, String>{'newPassword': newPassword},
  );

  /// مبيعات كل كاشير النهاردة بمعرّفه.
  ///
  /// التقرير محتاج صلاحية التقارير، واللي معندوش بيشوف الجدول من غير الأرقام
  /// بدل ما الشاشة كلها تقفل.
  Future<Map<String, double>> fetchTodaySales() async {
    final DateTime now = DateTime.now();

    try {
      final ApiResponse response = await _api.get(
        '/reports/cashiers',
        query: <String, dynamic>{
          'from': DateTime(now.year, now.month, now.day).toIso8601String(),
        },
      );

      return <String, double>{
        for (final Map<String, dynamic> row in response.list)
          row['cashier'] as String? ?? '':
              (row['sales'] as num?)?.toDouble() ?? 0,
      };
    } on ApiException catch (exception) {
      if (exception.isForbidden) return <String, double>{};
      rethrow;
    }
  }

  /// صلاحيات موظف بعينه فوق باقة دوره: [granted] زيادة و[revoked] استثناءات.
  Future<Employee> savePermissions(
    String id, {
    required Set<String> granted,
    required Set<String> revoked,
  }) async {
    final ApiResponse response = await _api.patch(
      '/users/$id/permissions',
      body: <String, dynamic>{
        'granted': granted.toList(),
        'revoked': revoked.toList(),
      },
    );

    return Employee.fromJson(response.object);
  }

  Future<RoleCatalog> fetchCatalog() async {
    final ApiResponse response = await _api.get('/users/catalog');
    return RoleCatalog.fromJson(response.object);
  }

  Future<RoleCatalog> saveRolePermissions(
    String role,
    Set<String> permissions,
  ) async {
    final ApiResponse response = await _api.patch(
      '/users/roles/$role',
      body: <String, dynamic>{'permissions': permissions.toList()},
    );
    return RoleCatalog.fromJson(response.object);
  }

  /// بيرجّع الدور لباقته الافتراضية.
  Future<RoleCatalog> resetRole(String role) async {
    final ApiResponse response = await _api.delete('/users/roles/$role');
    return RoleCatalog.fromJson(response.object);
  }
}
