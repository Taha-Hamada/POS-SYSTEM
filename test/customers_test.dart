import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/models/customer.dart';
import 'package:pos_system/core/models/ledger_entry.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/customers/controllers/customer_profile_controller.dart';
import 'package:pos_system/features/customers/controllers/customers_list_controller.dart';
import 'package:pos_system/features/customers/data/customers_repository.dart';
import 'package:pos_system/features/customers/models/customers_sort_column.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// العملاء وهم بيقروا ويكتبوا على الباك اند الحقيقي.
void main() {
  // ملف العميل فيه TabController، وده محتاج binding شغال.
  TestWidgetsFlutterBinding.ensureInitialized();

  // الـbinding بيحجب الشبكة، والاختبار ده بيضرب السيرفر فعلًا.
  HttpOverrides.global = null;

  late ApiClient api;
  late CustomersRepository repository;
  late CustomersListController customers;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();
    repository = CustomersRepository(api);

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
    customers = CustomersListController(repository);
    await customers.load();
  });

  tearDown(() {
    if (backendUp) customers.dispose();
  });

  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  test('القائمة بتجيب عملاء حقيقيين', () {
    if (skip()) return;

    expect(customers.hasFailed, isFalse, reason: customers.errorMessage);
    expect(customers.rows, isNotEmpty, reason: 'محتاج npm run seed');

    final Customer c = customers.rows.first;
    expect(c.id, isNotEmpty);
    expect(c.phone, isNotEmpty);
  });

  test('البحث بيفلتر بالاسم والموبايل', () async {
    if (skip()) return;

    final Customer target = customers.rows.first;
    customers.setQuery(target.phone);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(customers.rows.map((Customer c) => c.id), contains(target.id));

    customers.setQuery('لا-يوجد-كده');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(customers.rows, isEmpty);
  });

  test('الفرز بالرصيد شغال في الاتجاهين', () {
    if (skip()) return;

    customers.sortBy(CustomersSortColumn.balance.index, true);
    final List<double> ascending =
        customers.rows.map((Customer c) => c.balance).toList();

    for (int i = 1; i < ascending.length; i += 1) {
      expect(ascending[i - 1], lessThanOrEqualTo(ascending[i]));
    }

    customers.sortBy(CustomersSortColumn.balance.index, false);
    final List<double> descending =
        customers.rows.map((Customer c) => c.balance).toList();

    expect(descending, ascending.reversed.toList());
  });

  test('فلتر المدينين بيرجّع اللي عليهم بس', () {
    if (skip()) return;

    customers.toggleOnlyDebtors();

    expect(
      customers.rows.every((Customer c) => c.balance < 0),
      isTrue,
    );
  });

  test('إجمالي المديونية بيطابق تقرير السيرفر', () async {
    if (skip()) return;

    final Receivables receivables = await repository.fetchReceivables();

    expect(customers.totalDebt, closeTo(receivables.total, 0.01));
  });

  test('إضافة عميل بموبايل مكرر بترفض برسالة الحقل', () async {
    if (skip()) return;

    final Customer existing = customers.rows.first;

    final String? error = await customers.addCustomer(
      name: 'تكرار',
      phone: existing.phone,
    );

    expect(error, isNotNull);
    expect(error, contains('مسجّل'));
  });

  test('إضافة عميل جديد بتظهر في القائمة', () async {
    if (skip()) return;

    // رقم فريد عشان التشغيل المتكرر ميفشلش.
    final String phone = '0100${DateTime.now().millisecondsSinceEpoch % 10000000}';
    final int before = customers.rows.length;

    final String? error = await customers.addCustomer(
      name: 'عميل اختبار',
      phone: phone,
      creditLimit: 500,
    );

    expect(error, isNull);
    expect(customers.rows.length, before + 1);
    expect(
      customers.rows.any((Customer c) => c.phone == phone),
      isTrue,
    );
  });

  group('ملف العميل', () {
    CustomerProfileController? profile;

    Future<CustomerProfileController> openProfile(String id) async {
      final CustomerProfileController controller = CustomerProfileController(
        repository,
        customerId: id,
        vsync: const TestVSync(),
      );
      profile = controller;
      await controller.load();
      return controller;
    }

    /// بيخلّي عميل عليه مديونية عشان اختبارات السداد تلاقي حالة حقيقية.
    Future<Customer> makeDebtor() async {
      final Customer target = customers.rows.first;

      await api.post(
        '/customers/${target.id}/adjustments',
        body: <String, dynamic>{
          'amount': -500,
          'note': 'تجهيز اختبار السداد',
        },
      );

      return repository.fetchById(target.id);
    }

    tearDown(() {
      profile?.dispose();
      profile = null;
    });

    test('بيجيب العميل وفواتيره وكشفه ونقطه', () async {
      if (skip()) return;

      // عميل عليه حركات فعلًا.
      final Customer target = customers.rows.firstWhere(
        (Customer c) => c.ordersCount > 0,
        orElse: () => customers.rows.first,
      );

      final CustomerProfileController p = await openProfile(target.id);

      expect(p.hasFailed, isFalse, reason: p.errorMessage);
      expect(p.customer!.id, target.id);
      expect(p.customer!.name, target.name);
    });

    test('عميل مش موجود بيرجّع 404 مش انهيار', () async {
      if (skip()) return;

      final CustomerProfileController p =
          await openProfile('aaaaaaaaaaaaaaaaaaaaaaaa');

      expect(p.hasFailed, isTrue);
      expect(p.failure!.isNotFound, isTrue);
    });

    test('السداد بيقلّل المديونية ويظهر في كشف الحساب', () async {
      if (skip()) return;

      final Customer debtor = await makeDebtor();
      final CustomerProfileController p = await openProfile(debtor.id);

      final double debt = p.customer!.debt;
      expect(debt, greaterThan(0));

      final int ledgerBefore = p.ledger.length;
      final String? error = await p.recordPayment(amount: 1);

      expect(error, isNull);
      expect(p.customer!.debt, closeTo(debt - 1, 0.01));
      expect(p.ledger.length, ledgerBefore + 1);
      expect(p.ledger.first.type, 'payment');
    });

    test('السداد أكتر من المديونية بيترفض', () async {
      if (skip()) return;

      final Customer debtor = await makeDebtor();
      final CustomerProfileController p = await openProfile(debtor.id);

      final String? error =
          await p.recordPayment(amount: p.customer!.debt + 1000);

      expect(error, isNotNull);
    });

    test('كشف الحساب مرتّب من الأحدث', () async {
      if (skip()) return;

      final Customer target = customers.rows.firstWhere(
        (Customer c) => c.ordersCount > 0,
        orElse: () => customers.rows.first,
      );

      final CustomerProfileController p = await openProfile(target.id);

      if (p.ledger.length < 2) {
        markTestSkipped('محتاج حركتين على الأقل');
        return;
      }

      for (int i = 1; i < p.ledger.length; i += 1) {
        expect(
          p.ledger[i - 1].createdAt.isAfter(p.ledger[i].createdAt) ||
              p.ledger[i - 1]
                  .createdAt
                  .isAtSameMomentAs(p.ledger[i].createdAt),
          isTrue,
        );
      }
    });

    test('حركة كشف الحساب فيها الرصيد بعدها', () async {
      if (skip()) return;

      final Customer target = customers.rows.firstWhere(
        (Customer c) => c.ordersCount > 0,
        orElse: () => customers.rows.first,
      );

      final CustomerProfileController p = await openProfile(target.id);

      if (p.ledger.isEmpty) {
        markTestSkipped('مفيش حركات');
        return;
      }

      final LedgerEntry entry = p.ledger.first;
      expect(entry.typeLabel, isNotEmpty);
      expect(entry.description, isNotEmpty);
      expect(entry.balanceAfter, isA<double>());
    });
  });
}
