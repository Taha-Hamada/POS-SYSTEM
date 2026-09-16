import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/models/branch.dart';
import 'package:pos_system/core/models/employee.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/branches/controllers/branches_controller.dart';
import 'package:pos_system/features/branches/data/branch_management_repository.dart';
import 'package:pos_system/features/branches/models/branch_stats.dart';
import 'package:pos_system/features/employees_permissions/controllers/roles_permissions_controller.dart';
import 'package:pos_system/features/employees_permissions/data/employees_repository.dart';
import 'package:pos_system/features/employees_permissions/models/role_catalog.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Vsync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

/// الفروع والموظفين والصلاحيات وهي بتقرا وتكتب على الباك اند الحقيقي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // الـbinding بيحجب الشبكة، والاختبار ده بيضرب السيرفر فعلًا.
  HttpOverrides.global = null;

  late ApiClient api;
  late BranchManagementRepository branches;
  late EmployeesRepository employees;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();
    branches = BranchManagementRepository(api);
    employees = EmployeesRepository(api);

    try {
      await api.get('/health');
      backendUp = await SessionController(
        api,
      ).login(username: 'admin', password: 'Admin@12345');
    } on ApiException {
      backendUp = false;
    }
  });

  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  String unique() => DateTime.now().millisecondsSinceEpoch.toString();

  group('الفروع', () {
    test('الملخص بيرجّع الفروع بأرقامها والإجماليات', () async {
      if (skip()) return;

      final BranchesOverview overview = await branches.fetchOverview();

      expect(overview.branches, isNotEmpty);
      expect(overview.totals.branches, overview.branches.length);
      expect(
        overview.branches.where((BranchStats s) => s.branch.isMain),
        hasLength(1),
      );
    });

    test('إضافة وتعديل وقفل وتعطيل فرع', () async {
      if (skip()) return;

      final BranchesController controller = BranchesController(branches);
      final String code = 'T${unique().substring(7)}';

      expect(
        await controller.save(
          BranchInput(name: 'فرع اختبار', code: code, address: 'شارع الاختبار'),
        ),
        isNull,
      );

      Branch created = controller.rows
          .map((BranchStats s) => s.branch)
          .firstWhere((Branch b) => b.code == code);
      expect(created.address, 'شارع الاختبار');

      // الكود المكرر بيترفض برسالة مفهومة.
      expect(
        await controller.save(BranchInput(name: 'مكرر', code: code)),
        isNotNull,
      );

      expect(
        await controller.save(
          BranchInput(
            name: 'فرع اختبار معدّل',
            code: code,
            openFrom: '10:00',
            openTo: '22:00',
          ),
          existing: created,
        ),
        isNull,
      );

      created = controller.rows
          .map((BranchStats s) => s.branch)
          .firstWhere((Branch b) => b.code == code);
      expect(created.name, 'فرع اختبار معدّل');
      expect(created.openingHours, '10:00 – 22:00');

      expect(await controller.setOpen(created, isOpen: false), isNull);
      expect(
        controller.rows
            .firstWhere((BranchStats s) => s.branch.id == created.id)
            .branch
            .isOpen,
        isFalse,
      );

      expect(await controller.deactivate(created), isNull);
      expect(
        controller.rows.any((BranchStats s) => s.branch.id == created.id),
        isFalse,
      );

      controller.dispose();
    });
  });

  group('الموظفين', () {
    test('إضافة موظف وتعديله وإيقافه', () async {
      if (skip()) return;

      final Branch main = (await branches.fetchOverview()).branches
          .firstWhere((BranchStats s) => s.branch.isMain)
          .branch;
      final String username = 'test.${unique()}';

      final Employee created = await employees.create(
        name: 'موظف اختبار',
        username: username,
        password: 'Test@12345',
        role: 'cashier',
        branchId: main.id,
        salary: 5000,
      );
      expect(created.branchId, main.id);
      expect(created.roleLabel, 'كاشير');

      // غير مدير النظام لازم يبقى على فرع.
      await expectLater(
        employees.update(created.id, <String, dynamic>{'branch': null}),
        throwsA(isA<ApiException>()),
      );

      final Employee updated = await employees.update(
        created.id,
        <String, dynamic>{'role': 'accountant', 'salary': 7000},
      );
      expect(updated.role, 'accountant');
      expect(updated.salary, 7000);

      final Employee stopped = await employees.setActive(
        created.id,
        isActive: false,
      );
      expect(stopped.isActive, isFalse);

      final List<Employee> all = await employees.fetchAll();
      expect(all.any((Employee e) => e.username == username), isTrue);
    });
  });

  group('الصلاحيات', () {
    test('حفظ باقة دور واستعادتها للافتراضي', () async {
      if (skip()) return;

      final RolesPermissionsController controller = RolesPermissionsController(
        employees,
        vsync: _Vsync(),
        canEdit: true,
      );
      await controller.load();

      expect(controller.role?.value, 'cashier');
      final Set<String> original = Set<String>.of(controller.role!.permissions);

      try {
        controller.toggle('report:view', true);
        expect(controller.dirty, isTrue);

        expect(await controller.save(), isNull);
        expect(controller.dirty, isFalse);
        expect(controller.role!.customized, isTrue);
        expect(controller.role!.permissions, contains('report:view'));

        // الكاشير اللي بيدخل دلوقتي بياخد الباقة الجديدة.
        final ApiClient cashierApi = ApiClient();
        final SessionController cashier = SessionController(cashierApi);
        if (await cashier.login(username: 'cashier', password: 'Cashier@123')) {
          expect(cashier.user!.permissions, contains('report:view'));
        }
        cashierApi.dispose();

        // مدير النظام مبيتعدّلش.
        controller.selectRole('admin');
        expect(controller.editable, isFalse);
        controller.selectRole('cashier');
      } finally {
        expect(await controller.resetToDefaults(), isNull);
      }

      final RoleInfo cashierRole = controller.role!;
      expect(cashierRole.customized, isFalse);
      expect(cashierRole.permissions, original);

      controller.dispose();
    });
  });
}
