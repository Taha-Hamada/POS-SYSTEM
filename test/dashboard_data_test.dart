import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/dashboard/data/reports_repository.dart';
import 'package:pos_system/core/models/product.dart';
import 'package:pos_system/features/dashboard/models/dashboard_data.dart';
import 'package:pos_system/features/pos_sale/controllers/sales_session_controller.dart';
import 'package:pos_system/features/pos_sale/data/pos_repository.dart';
import 'package:pos_system/features/reports/data/reports_repository.dart'
    as full_reports;
import 'package:pos_system/features/reports/models/report_rows.dart';
import 'package:pos_system/features/returns/controllers/returns_controller.dart';
import 'package:pos_system/features/returns/data/returns_repository.dart';
import 'package:pos_system/features/returns/models/return_line.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// الداشبورد وهو بيقرا من الباك اند الحقيقي.
/// محتاج السيرفر شغال وفيه فواتير، وإلا الاختبارات بتتخطّى.
void main() {
  late ApiClient api;
  late ReportsRepository reports;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();
    reports = ReportsRepository(api);

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

  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  test('المرتجع الكامل بيلغي أثر الفاتورة على صافي الربح', () async {
    if (skip()) return;

    final SalesSessionController sales =
        SalesSessionController(PosRepository(api));
    await sales.load();

    final Product target = sales.products.firstWhere(
      (Product p) =>
          p.trackStock && p.price > 0 && p.cost > 0 && p.cost < p.price &&
          p.stock > 10,
    );

    final double before =
        (await reports.fetchDashboard(days: 7)).period.netProfit;

    for (int i = 0; i < 4; i += 1) {
      sales.active.addProduct(target);
    }
    final CompletedInvoice invoice = await sales.checkout(<PaymentInput>[
      PaymentInput(method: 'cash', amount: 100000),
    ]);

    final double afterSale =
        (await reports.fetchDashboard(days: 7)).period.netProfit;

    // ربح الفاتورة = الإجمالي ناقص الضريبة والتكلفة، والتكلفة بتتقرا من
    // الفاتورة المحفوظة لأن رد الاعتماد مش شايلها.
    final Map<String, dynamic> saved =
        (await api.get('/invoices/${invoice.id}')).object;
    final double costTotal = (saved['costTotal'] as num?)?.toDouble() ?? 0;
    final double invoiceProfit = invoice.total - invoice.taxAmount - costTotal;
    expect(afterSale - before, closeTo(invoiceProfit, 0.05),
        reason: 'البيع بيزوّد صافي الربح بربحه');

    final ReturnsController returns = ReturnsController(ReturnsRepository(api));
    await returns.search(invoice.number);
    final ReturnLine line = returns.lines.first;
    returns
      ..setLineSelected(line, true)
      ..setReturnQuantity(line, 4)
      ..setReason('اختبار التقارير');
    expect(await returns.submit(), isNotNull, reason: returns.error);

    final double afterReturn =
        (await reports.fetchDashboard(days: 7)).period.netProfit;

    // المرتجع بيرجّع البضاعة بتكلفتها والضريبة للعميل، فالأثر الصافي صفر.
    // قبل الإصلاح كان بيطرح إجمالي المرتجع فيطلّع خسارة وهمية بقيمة
    // التكلفة والضريبة.
    expect(afterReturn, closeTo(before, 0.05),
        reason: 'الإرجاع الكامل بيرجّع صافي الربح لأصله');

    returns.dispose();
    sales.dispose();
  });

  test('قيمة المخزون في الداشبورد = مجموع تقرير الأقسام', () async {
    if (skip()) return;

    final DashboardData data = await reports.fetchDashboard(days: 7);
    final List<InventoryReportRow> rows =
        await full_reports.ReportsRepository(api).fetchInventory();

    final double cost =
        rows.fold<double>(0, (double s, InventoryReportRow r) => s + r.cost);
    final double retail =
        rows.fold<double>(0, (double s, InventoryReportRow r) => s + r.retail);

    // الشاشتين بتقرا من نفس الأرصدة، فأي اختلاف معناه إن واحدة بتفلتر غير التانية.
    expect(data.inventoryCostValue, closeTo(cost, 0.05));
    expect(data.inventoryRetailValue, closeTo(retail, 0.05));
  });

  test('الداشبورد بيرجّع أرقام الفترة والسلسلة', () async {
    if (skip()) return;

    final DashboardData data = await reports.fetchDashboard(days: 30);

    expect(data.series, hasLength(30), reason: 'يوم لكل نقطة');
    expect(data.period.invoices, greaterThan(0),
        reason: 'محتاج فواتير في الداتابيز');
    expect(data.period.sales, greaterThan(0));
    expect(data.period.averageTicket, greaterThan(0));
  });

  test('طول السلسلة بيتغيّر بتغيّر الفترة', () async {
    if (skip()) return;

    expect((await reports.fetchDashboard(days: 7)).series, hasLength(7));
    expect((await reports.fetchDashboard(days: 90)).series, hasLength(90));
  });

  test('آخر يوم في السلسلة هو النهاردة', () async {
    if (skip()) return;

    final DashboardData data = await reports.fetchDashboard(days: 7);
    final DateTime now = DateTime.now();
    final DateTime last = data.series.last.date;

    expect(last.year, now.year);
    expect(last.month, now.month);
    expect(last.day, now.day);
  });

  test('مبيعات النهاردة بتظهر في آخر نقطة', () async {
    if (skip()) return;

    final DashboardData data = await reports.fetchDashboard(days: 7);

    if (data.today.invoices == 0) {
      markTestSkipped('مفيش مبيعات النهاردة');
      return;
    }

    // مقارنة تقريبية: المجموع في السلسلة بيتقرّب على حدة عن مجموع اليوم.
    expect(data.series.last.sales, closeTo(data.today.sales, 0.01),
        reason: 'تقسيم الأيام لازم يبقى بتوقيت السيرفر');
  });

  test('نسبة التغيّر بتتحسب من الفترة السابقة', () async {
    if (skip()) return;

    final DashboardData data = await reports.fetchDashboard(days: 30);

    expect(
      data.salesChange,
      DashboardData.changeBetween(data.period.sales, data.previous.sales),
    );

    // فترة سابقة فاضية وحالية فيها مبيعات = زيادة 100%.
    if (data.previous.sales == 0 && data.period.sales > 0) {
      expect(data.salesChange, 100);
    }
  });

  test('طرق الدفع بترجع بالمحصّل الفعلي', () async {
    if (skip()) return;

    final DashboardData data = await reports.fetchDashboard(days: 30);

    expect(data.paymentMethods, isNotEmpty);
    expect(
      data.paymentMethods.values.every((double amount) => amount >= 0),
      isTrue,
    );
  });

  test('أفضل المنتجات مرتّبة بالإيراد', () async {
    if (skip()) return;

    final List<TopProduct> top =
        (await reports.fetchDashboard(days: 30)).topProducts;

    expect(top, isNotEmpty);
    for (int i = 1; i < top.length; i += 1) {
      expect(top[i - 1].revenue, greaterThanOrEqualTo(top[i].revenue));
    }
  });

  test('قيمة المخزون بالتكلفة أقل من قيمته بالبيع', () async {
    if (skip()) return;

    final DashboardData data = await reports.fetchDashboard(days: 30);

    expect(data.inventoryCostValue, greaterThan(0));
    expect(data.inventoryRetailValue, greaterThan(data.inventoryCostValue));
  });

  test('صافي الربح بيخصم ربح المرتجعات مش إجماليها', () async {
    if (skip()) return;

    final DashboardData data = await reports.fetchDashboard(days: 30);

    expect(
      data.period.netProfit,
      closeTo(
        data.period.profit - data.period.returnsProfit - data.period.expenses,
        0.01,
      ),
    );

    // إجمالي المرتجع فيه الضريبة والتكلفة كمان، فأثره على الربح أقل منه.
    if (data.period.returns > 0) {
      expect(data.period.returnsProfit, lessThan(data.period.returns));
    }
  });

  test('مقارنة الفروع بترجّع نصيب كل فرع', () async {
    if (skip()) return;

    final List<BranchStats> branches = await reports.fetchBranches();

    expect(branches, isNotEmpty);
    expect(branches.first.name, isNotEmpty);

    final double totalShare = branches.fold<double>(
      0,
      (double sum, BranchStats b) => sum + b.share,
    );
    expect(totalShare, closeTo(100, 0.5));
  });

  test('فلتر الفرع بيقلّل الأرقام', () async {
    if (skip()) return;

    final List<BranchStats> branches = await reports.fetchBranches();
    if (branches.length < 2) {
      markTestSkipped('محتاج فرعين على الأقل فيهم مبيعات');
      return;
    }

    final DashboardData all = await reports.fetchDashboard(days: 90);
    final DashboardData one =
        await reports.fetchDashboard(days: 90, branchId: branches.first.id);

    expect(one.period.sales, lessThanOrEqualTo(all.period.sales));
  });
}
