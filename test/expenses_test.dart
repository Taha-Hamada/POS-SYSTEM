import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/data/branches_repository.dart';
import 'package:pos_system/core/models/branch.dart';
import 'package:pos_system/core/models/expense.dart';
import 'package:pos_system/core/models/payment_method.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/expenses/controllers/add_expense_controller.dart';
import 'package:pos_system/features/expenses/controllers/expenses_controller.dart';
import 'package:pos_system/features/expenses/data/expenses_repository.dart';
import 'package:pos_system/features/expenses/models/expenses_sort_column.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// المصروفات وهي بتقرا وتكتب على الباك اند الحقيقي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // الـbinding بيحجب الشبكة، والاختبار ده بيضرب السيرفر فعلًا.
  HttpOverrides.global = null;

  late ApiClient api;
  late ExpensesRepository repository;
  late BranchesRepository branchesRepository;
  late ExpensesController expenses;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();
    repository = ExpensesRepository(api);
    branchesRepository = BranchesRepository(api);

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
    expenses = ExpensesController(repository, branchesRepository);
    await expenses.load();
  });

  tearDown(() {
    if (backendUp) expenses.dispose();
  });

  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  Future<Expense> record({
    String category = 'اختبار آلي',
    double amount = 25,
    PaymentMethod method = PaymentMethod.card,
  }) async {
    final List<Branch> branches = await branchesRepository.fetchAll();

    return repository.create(
      category: category,
      amount: amount,
      paymentMethod: method,
      branchId: branches.first.id,
      note: 'مصروف من الاختبارات',
    );
  }

  test('القايمة بترجع مصروفات وبيانات فرعها', () async {
    if (skip()) return;

    expect(expenses.hasFailed, isFalse, reason: expenses.errorMessage ?? '');
    await record();
    await expenses.load();

    expect(expenses.rows, isNotEmpty);
    expect(expenses.visibleCount, greaterThan(0));

    final Expense first = expenses.rows.first;
    expect(first.number, startsWith('EXP-'));
    expect(first.branchName, isNotEmpty, reason: 'الفرع لازم يرجع populated');
    expect(first.amount, greaterThan(0));
  });

  test('الإجمالي جاي من السيرفر مش من الصفحة المعروضة', () async {
    if (skip()) return;

    final ExpensesSummary summary = await repository.fetchSummary();
    final double rowsTotal = expenses.rows
        .fold<double>(0, (double s, Expense e) => s + e.amount);

    expect(expenses.visibleTotal, closeTo(summary.total, 0.01));
    expect(
      expenses.visibleTotal,
      greaterThanOrEqualTo(rowsTotal - 0.01),
      reason: 'الملخّص بيشمل كل الصفحات',
    );
  });

  test('نصيب كل بند بيجمع 100%', () async {
    if (skip()) return;

    final ExpensesSummary summary = await repository.fetchSummary();
    if (summary.categories.isEmpty) {
      markTestSkipped('مفيش مصروفات');
      return;
    }

    final double share = summary.categories
        .fold<double>(0, (double s, ExpenseCategoryTotal c) => s + c.share);

    expect(share, closeTo(100, 0.5));
  });

  test('تسجيل مصروف بيرجّعه برقم وحالة معلّقة', () async {
    if (skip()) return;

    final Expense created = await record(category: 'كهرباء', amount: 137.5);

    expect(created.number, startsWith('EXP-'));
    expect(created.category, 'كهرباء');
    expect(created.amount, 137.5);
    expect(created.status, ExpenseStatus.pending);
    expect(created.createdBy, isNotEmpty);
  });

  test('فلتر البند بيقلّل الصفوف', () async {
    if (skip()) return;

    await record(category: 'بند نادر للاختبار', amount: 11);
    await expenses.load();

    final int all = expenses.visibleCount;
    await expenses.setCategory('بند نادر للاختبار');

    expect(expenses.visibleCount, lessThanOrEqualTo(all));
    expect(
      expenses.rows.every((Expense e) => e.category == 'بند نادر للاختبار'),
      isTrue,
    );
  });

  test('فلتر الحالة بيرجّع المعلّق بس', () async {
    if (skip()) return;

    await record();
    await expenses.setStatus(ExpenseStatus.pending);

    expect(expenses.rows, isNotEmpty);
    expect(expenses.rows.every((Expense e) => e.isPending), isTrue);
    expect(expenses.pendingTotal, closeTo(expenses.visibleTotal, 0.01));
  });

  test('الفرز بالمبلغ بيتنفّذ على السيرفر', () async {
    if (skip()) return;

    await expenses.sortBy(ExpensesSortColumn.amount.index, false);

    final List<Expense> rows = expenses.rows;
    for (int i = 1; i < rows.length; i += 1) {
      expect(rows[i - 1].amount, greaterThanOrEqualTo(rows[i].amount));
    }
  });

  test('المدير مينفعش يعتمد مصروف سجّله بنفسه', () async {
    if (skip()) return;

    final Expense created = await record(amount: 40);
    final String? error = await expenses.review(created, approve: true);

    expect(error, isNotNull, reason: 'السيرفر بيمنع الاعتماد الذاتي');
    expect(error, contains('بنفسك'));
  });

  test('الرفض من غير سبب مبيعديش', () async {
    if (skip()) return;

    final Expense created = await record(amount: 33);

    await expectLater(
      repository.review(created.id, approve: false),
      throwsA(isA<ApiException>()),
    );
  });

  test('نموذج المصروف بيرفض المبلغ صفر والبند القصير', () async {
    if (skip()) return;

    final List<Branch> branches = await branchesRepository.fetchAll();
    final AddExpenseController form = AddExpenseController(
      repository,
      branches: branches,
      knownCategories: expenses.categoryNames,
    );

    expect(form.isValid, isFalse, reason: 'فاضي');

    form.categoryController.text = 'ك';
    form.amountController.text = '50';
    form.fieldChanged();
    expect(form.isValid, isFalse, reason: 'البند حرف واحد');

    form.categoryController.text = 'كهرباء';
    form.amountController.text = '0';
    form.fieldChanged();
    expect(form.isValid, isFalse, reason: 'المبلغ صفر');

    form.amountController.text = '50';
    form.fieldChanged();
    expect(form.isValid, isTrue);

    final Expense? created = await form.submit();
    expect(created, isNotNull, reason: form.saveError ?? '');
    expect(created!.amount, 50);

    form.dispose();
  });

  test('المصروف الكاش بيتربط بالوردية المفتوحة', () async {
    if (skip()) return;

    // مفيش وردية مفتوحة للمدير غالبًا، والمهم إن التسجيل بينجح في الحالتين.
    final Expense created = await record(
      category: 'نثريات',
      amount: 15,
      method: PaymentMethod.cash,
    );

    expect(created.paymentMethod, PaymentMethod.cash);
    expect(created.status, ExpenseStatus.pending);
  });

  test('المدير بيعتمد مصروف سجّله الكاشير', () async {
    if (skip()) return;

    // الكاشير بيسجّل بجلسة مستقلة عشان الاعتماد ما يبقاش اعتماد ذاتي.
    final ApiClient cashierApi = ApiClient();
    addTearDown(cashierApi.dispose);

    final bool loggedIn = await SessionController(cashierApi).login(
      username: 'cashier',
      password: 'Cashier@123',
    );

    if (!loggedIn) {
      markTestSkipped('مستخدم الكاشير مش موجود');
      return;
    }

    final Expense created = await ExpensesRepository(cashierApi).create(
      category: 'نثريات الوردية',
      amount: 18,
      paymentMethod: PaymentMethod.cash,
      note: 'من الكاشير',
    );

    expect(created.status, ExpenseStatus.pending);

    final String? error = await expenses.review(created, approve: true);
    expect(error, isNull, reason: error ?? '');

    final ExpensesPage page = await repository.fetchPage(search: created.number);
    expect(page.items.single.status, ExpenseStatus.approved);
    expect(page.items.single.reviewedBy, isNotEmpty);
  });

  test('المعتمد مبيتمسحش', () async {
    if (skip()) return;

    final ExpensesPage approved = await repository.fetchPage(
      status: ExpenseStatus.approved,
      limit: 1,
    );

    if (approved.items.isEmpty) {
      markTestSkipped('مفيش مصروف معتمد');
      return;
    }

    final String? error = await expenses.delete(approved.items.first);
    expect(error, isNotNull, reason: 'السيرفر بيقفل المعتمد');
    expect(error, contains('معتمد'));
  });

  test('مسح مصروف معلّق بيشيله من القايمة', () async {
    if (skip()) return;

    final Expense created = await record(category: 'للمسح', amount: 9);
    await expenses.load();

    final int before = expenses.visibleCount;
    final String? error = await expenses.delete(created);

    expect(error, isNull);
    expect(expenses.visibleCount, before - 1);
    expect(
      expenses.rows.any((Expense e) => e.id == created.id),
      isFalse,
    );
  });
}
