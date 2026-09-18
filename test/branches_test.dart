import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/models/branch.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/branches/controllers/branches_controller.dart';
import 'package:pos_system/features/branches/data/branch_management_repository.dart';
import 'package:pos_system/features/branches/models/branch_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// الفروع وهي بتقرا وتكتب على الباك اند الحقيقي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // الـbinding بيحجب الشبكة، والاختبار ده بيضرب السيرفر فعلًا.
  HttpOverrides.global = null;

  late ApiClient api;
  late BranchManagementRepository branches;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();
    branches = BranchManagementRepository(api);

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
}
