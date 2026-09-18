import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/data/branches_repository.dart';
import 'package:pos_system/core/models/branch.dart';
import 'package:pos_system/core/models/purchase_order.dart';
import 'package:pos_system/core/models/supplier.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/cashier_shift/controllers/current_shift_controller.dart';
import 'package:pos_system/features/cashier_shift/data/shift_repository.dart';
import 'package:pos_system/features/purchase_orders/data/purchases_repository.dart';
import 'package:pos_system/features/suppliers/controllers/supplier_profile_controller.dart';
import 'package:pos_system/features/suppliers/controllers/suppliers_list_controller.dart';
import 'package:pos_system/features/suppliers/data/suppliers_repository.dart';
import 'package:pos_system/features/suppliers/models/supplied_product.dart';
import 'package:pos_system/features/suppliers/models/supplier_filter.dart';
import 'package:pos_system/features/suppliers/models/suppliers_sort_column.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// الموردين وهم بيقروا ويكتبوا على الباك اند الحقيقي.
void main() {
  // ملف المورد فيه TabController، وده محتاج binding شغال.
  TestWidgetsFlutterBinding.ensureInitialized();

  // الـbinding بيحجب الشبكة، والاختبار ده بيضرب السيرفر فعلًا.
  HttpOverrides.global = null;

  late ApiClient api;
  late SuppliersRepository repository;
  late PurchasesRepository purchases;
  late SuppliersListController suppliers;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();
    repository = SuppliersRepository(api);
    purchases = PurchasesRepository(api);

    try {
      await api.get('/health');
      final SessionController auth = SessionController(api);
      backendUp = await auth.login(
        username: 'admin',
        password: 'Admin@12345',
      );
    } on ApiException {
      backendUp = false;
    }
  });

  setUp(() async {
    if (!backendUp) return;
    suppliers = SuppliersListController(repository);
    await suppliers.load();
  });

  tearDown(() {
    if (backendUp) suppliers.dispose();
  });

  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  /// رقم فريد عشان المحاولات المتكررة ما تتصادمش على قيد التفرّد.
  String uniquePhone() =>
      '010${DateTime.now().microsecondsSinceEpoch.remainder(100000000)}';

  Future<Supplier> newSupplier({String name = 'مورد الاختبار'}) =>
      repository.create(
        name: name,
        phone: uniquePhone(),
        contactPerson: 'مسؤول الاختبار',
        paymentTermDays: 30,
      );

  test('القايمة بترجع موردين بأرصدتهم', () async {
    if (skip()) return;

    expect(suppliers.hasFailed, isFalse, reason: suppliers.errorMessage ?? '');
    expect(suppliers.rows, isNotEmpty);
    expect(suppliers.visibleCount, greaterThan(0));
    expect(suppliers.rows.first.name, isNotEmpty);
    expect(suppliers.rows.first.phone, isNotEmpty);
  });

  test('إجمالي المستحقات محسوب على السيرفر مش على الصفحة', () async {
    if (skip()) return;

    final PayablesSummary payables = await repository.fetchPayables();

    expect(suppliers.totalDue, closeTo(payables.total, 0.01));
    expect(suppliers.dueSuppliersCount, payables.count);
    expect(suppliers.totalDue, greaterThanOrEqualTo(suppliers.visibleDue - 0.01));
  });

  test('إضافة مورد بترجّعه من السيرفر', () async {
    if (skip()) return;

    final Supplier created = await newSupplier(name: 'شركة النور للتوريدات');

    expect(created.id, isNotEmpty);
    expect(created.name, 'شركة النور للتوريدات');
    expect(created.contactPerson, 'مسؤول الاختبار');
    expect(created.paymentTermDays, 30);
    expect(created.balanceDue, 0);
    expect(created.isActive, isTrue);
  });

  test('رقم موبايل مكرر بيترفض برسالة واضحة', () async {
    if (skip()) return;

    final Supplier created = await newSupplier();

    await expectLater(
      repository.create(name: 'مكرر', phone: created.phone),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.message,
          'message',
          contains('مسجّل'),
        ),
      ),
    );
  });

  test('فلتر «عليه مستحقات» بيرجّع اللي رصيده موجب بس', () async {
    if (skip()) return;

    await suppliers.setFilter(SupplierFilter.due);

    expect(suppliers.rows.every((Supplier s) => s.balanceDue > 0), isTrue);
    expect(suppliers.visibleCount, lessThanOrEqualTo(suppliers.dueSuppliersCount));
  });

  test('فلتر الموقوفين بيرجّع غير النشطين', () async {
    if (skip()) return;

    await suppliers.setFilter(SupplierFilter.inactive);

    expect(suppliers.rows.every((Supplier s) => !s.isActive), isTrue);
  });

  test('الفرز بالمستحق بيتنفّذ على السيرفر', () async {
    if (skip()) return;

    await suppliers.sortBy(SuppliersSortColumn.balance.index, false);

    final List<Supplier> rows = suppliers.rows;
    for (int i = 1; i < rows.length; i += 1) {
      expect(rows[i - 1].balanceDue, greaterThanOrEqualTo(rows[i].balanceDue));
    }
  });

  test('البحث بالاسم بيقلّل النتائج', () async {
    if (skip()) return;

    final Supplier created = await newSupplier(name: 'مورد نادر جدا للاختبار');
    final SuppliersPage page =
        await repository.fetchPage(search: 'مورد نادر جدا للاختبار');

    expect(page.items, isNotEmpty);
    expect(page.items.any((Supplier s) => s.id == created.id), isTrue);
  });

  test('تعطيل مورد عليه مستحقات بيترفض', () async {
    if (skip()) return;

    final SuppliersPage due = await repository.fetchPage(hasDue: true, limit: 1);
    if (due.items.isEmpty) {
      markTestSkipped('مفيش مورد عليه مستحقات');
      return;
    }

    final String? error =
        await suppliers.setActiveState(due.items.first, isActive: false);

    expect(error, isNotNull);
    expect(error, contains('مستحقات'));
  });

  test('تعطيل وتفعيل مورد صافي بينجح', () async {
    if (skip()) return;

    final Supplier created = await newSupplier(name: 'مورد للتعطيل');

    expect(
      await suppliers.setActiveState(created, isActive: false),
      isNull,
    );
    expect((await repository.fetchOne(created.id)).isActive, isFalse);

    expect(await suppliers.setActiveState(created, isActive: true), isNull);
    expect((await repository.fetchOne(created.id)).isActive, isTrue);
  });

  test('تعديل بيانات المورد بيحفظ الحقول المبعوتة بس', () async {
    if (skip()) return;

    final Supplier created = await newSupplier(name: 'قبل التعديل');

    final Supplier updated = await repository.update(
      created.id,
      name: 'بعد التعديل',
      contactPerson: 'مسؤول جديد',
    );

    expect(updated.name, 'بعد التعديل');
    expect(updated.contactPerson, 'مسؤول جديد');
    expect(updated.phone, created.phone, reason: 'الرقم مبعتش فمتغيرش');
    expect(updated.paymentTermDays, created.paymentTermDays);
  });

  test('سداد أكبر من المستحق بيترفض', () async {
    if (skip()) return;

    final SuppliersPage due = await repository.fetchPage(hasDue: true, limit: 1);
    if (due.items.isEmpty) {
      markTestSkipped('مفيش مورد عليه مستحقات');
      return;
    }

    final Supplier supplier = due.items.first;

    await expectLater(
      repository.pay(supplier.id, amount: supplier.balanceDue + 1000),
      throwsA(isA<ApiException>()),
    );
  });

  test('سداد جزئي بيقلّل المستحق وبينزل من الدرج', () async {
    if (skip()) return;

    final SuppliersPage due = await repository.fetchPage(hasDue: true, limit: 1);
    if (due.items.isEmpty) {
      markTestSkipped('مفيش مورد عليه مستحقات');
      return;
    }

    final Supplier before = due.items.first;
    final double payment = before.balanceDue / 2;
    if (payment <= 0) {
      markTestSkipped('المستحق صغير أوي');
      return;
    }

    // السداد بيطلع من درج الوردية، فلازم يكون فيه كاش يغطيه.
    // المدير مش مربوط بفرع، فالوردية محتاجة فرع صريح.
    final List<Branch> branches = await BranchesRepository(api).fetchAll();
    final CurrentShiftController shifts = CurrentShiftController(
      ShiftRepository(api),
      branchId: branches.first.id,
    );
    await shifts.load();
    if (!shifts.isOpen) {
      final String? error = await shifts.open(0);
      expect(error, isNull, reason: error);
    }
    final String? funded = await shifts.addCash(
      isIn: true,
      amount: payment + 100,
      reason: 'تمويل اختبار السداد',
    );
    expect(funded, isNull, reason: funded);

    final double drawerBefore = shifts.totals.expectedCash;
    final Supplier after = await repository.pay(before.id, amount: payment);
    await shifts.refreshTotals();

    expect(after.balanceDue, closeTo(before.balanceDue - payment, 0.01));
    expect(shifts.totals.expectedCash, closeTo(drawerBefore - payment, 0.01),
        reason: 'الفلوس بتخرج من الدرج فعلًا');

    shifts.dispose();
  });

  test('السداد بأكتر من اللي في الدرج بيترفض', () async {
    if (skip()) return;

    final SuppliersPage due = await repository.fetchPage(hasDue: true, limit: 1);
    if (due.items.isEmpty) {
      markTestSkipped('مفيش مورد عليه مستحقات');
      return;
    }

    final List<Branch> branches = await BranchesRepository(api).fetchAll();
    final CurrentShiftController shifts = CurrentShiftController(
      ShiftRepository(api),
      branchId: branches.first.id,
    );
    await shifts.load();
    if (!shifts.isOpen) await shifts.open(0);

    final Supplier supplier = due.items.first;
    final double tooMuch = shifts.totals.expectedCash + 1000;

    if (tooMuch <= supplier.balanceDue) {
      await expectLater(
        repository.pay(supplier.id, amount: tooMuch),
        throwsA(isA<ApiException>()),
      );

      final Supplier fresh = await repository.fetchOne(supplier.id);
      expect(fresh.balanceDue, closeTo(supplier.balanceDue, 0.01),
          reason: 'المستحق مايتغيرش لو السداد اترفض');
    }

    shifts.dispose();
  });

  test('ملف المورد بيجمع بياناته وأصنافه وأوامره', () async {
    if (skip()) return;

    // مورد ليه أوامر فعلًا عشان التبويبات ما تبقاش فاضية.
    final PurchaseOrdersPage orders = await purchases.fetchPage(limit: 1);
    if (orders.items.isEmpty) {
      markTestSkipped('مفيش أوامر شراء');
      return;
    }

    final String supplierId = orders.items.first.supplierId;

    final SupplierProfileController profile = SupplierProfileController(
      repository,
      purchases,
      supplierId: supplierId,
      vsync: const TestVSync(),
    );

    await profile.load();

    expect(profile.hasFailed, isFalse, reason: profile.errorMessage ?? '');
    expect(profile.supplier, isNotNull);
    expect(profile.supplier!.id, supplierId);
    expect(profile.orders, isNotEmpty);
    expect(
      profile.orders.every((PurchaseOrder o) => o.supplierId == supplierId),
      isTrue,
    );

    profile.dispose();
  });

  test('الأصناف الموردة محسوبة من أوامر الشراء', () async {
    if (skip()) return;

    final PurchaseOrdersPage orders = await purchases.fetchPage(limit: 1);
    if (orders.items.isEmpty) {
      markTestSkipped('مفيش أوامر شراء');
      return;
    }

    final PurchaseOrder order = await purchases.fetchOne(orders.items.first.id);
    final List<SuppliedProduct> supplied =
        await repository.fetchSuppliedProducts(order.supplierId);

    expect(supplied, isNotEmpty);

    // كل صنف في الأمر لازم يبقى في القايمة.
    for (final PurchaseOrderLine line in order.lines) {
      expect(
        supplied.any((SuppliedProduct p) => p.id == line.productId),
        isTrue,
        reason: 'الصنف ${line.name} مش في الأصناف الموردة',
      );
    }

    expect(supplied.first.sku, isNotEmpty);
    expect(supplied.first.lastUnitCost, greaterThan(0));
  });

  test('المورد اللي مش موجود بيرجّع حالة «غير موجود»', () async {
    if (skip()) return;

    final SupplierProfileController profile = SupplierProfileController(
      repository,
      purchases,
      // معرّف صالح الشكل لكن مش موجود.
      supplierId: '000000000000000000000000',
      vsync: const TestVSync(),
    );

    await profile.load();

    expect(profile.supplier, isNull);
    expect(profile.notFound, isTrue);

    profile.dispose();
  });
}
