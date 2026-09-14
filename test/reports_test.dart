import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/dashboard/models/dashboard_data.dart';
import 'package:pos_system/features/reports/controllers/reports_controller.dart';
import 'package:pos_system/features/reports/data/reports_repository.dart';
import 'package:pos_system/features/reports/models/report_period.dart';
import 'package:pos_system/features/reports/models/report_rows.dart';
import 'package:pos_system/features/reports/models/report_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// التقارير وهي بتقرا من الباك اند الحقيقي.
void main() {
  // الكنترولر فيه AnimationController، وده محتاج binding شغال.
  TestWidgetsFlutterBinding.ensureInitialized();

  // الـbinding بيركّب HttpOverrides بيحجب أي طلب شبكة حقيقي،
  // والاختبار ده بيضرب الباك اند فعلًا، فبنشيله.
  HttpOverrides.global = null;

  late ApiClient api;
  late ReportsController reports;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();

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

  setUp(() {
    if (!backendUp) return;
    reports = ReportsController(
      ReportsRepository(api),
      vsync: const TestVSync(),
    );
  });

  tearDown(() {
    if (backendUp) reports.dispose();
  });

  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  test('تقرير المبيعات بيجيب السلسلة وإجمالياتها', () async {
    if (skip()) return;

    await reports.load();

    expect(reports.hasFailed, isFalse, reason: reports.errorMessage);
    expect(reports.series, isNotEmpty);
    expect(reports.totalSales, greaterThan(0), reason: 'محتاج فواتير');
    expect(reports.totalInvoices, greaterThan(0));
    expect(reports.avgInvoice, greaterThan(0));
  });

  test('مجموع السطور بيساوي الإجمالي', () async {
    if (skip()) return;
    await reports.load();

    final double sum = reports.series
        .fold<double>(0, (double s, SalesPoint p) => s + p.sales);

    expect(reports.totalSales, closeTo(sum, 0.01));
  });

  test('الضريبة اليومية بتيجي مع السلسلة', () async {
    if (skip()) return;
    await reports.load();

    final SalesPoint withSales =
        reports.series.firstWhere((SalesPoint p) => p.sales > 0);

    expect(withSales.tax, greaterThan(0),
        reason: 'السيرفر بيحسبها، والجدول بيعرضها عمود مستقل');
  });

  test('الفترة الطويلة بتتجمّع أسبوعيًا في الرسم', () async {
    if (skip()) return;

    await reports.setPeriod(ReportPeriod.quarter);

    expect(reports.isWeeklyChart, isTrue);
    expect(reports.chartPoints.length, lessThan(reports.series.length));

    final double chartSum = reports.chartPoints
        .fold<double>(0, (double s, SalesPoint p) => s + p.sales);
    expect(chartSum, closeTo(reports.totalSales, 0.01),
        reason: 'التجميع ملازمش يضيّع مبيعات');
  });

  test('تقرير الأرباح بيجمّع بالأقسام', () async {
    if (skip()) return;

    await reports.selectReport(ReportType.profit);

    expect(reports.categoryRows, isNotEmpty);

    final CategoryReportRow row = reports.categoryRows.first;
    expect(row.name, isNotEmpty);
    expect(row.revenue, greaterThan(0));
    expect(row.cost, closeTo(row.revenue - row.profit, 0.01));
    expect(row.margin, greaterThan(0));

    final double shares = reports.categoryRows
        .fold<double>(0, (double s, CategoryReportRow r) => s + r.share);
    expect(shares, closeTo(100, 0.5));
  });

  test('تقرير المنتجات مرتّب بالإيراد', () async {
    if (skip()) return;

    await reports.selectReport(ReportType.products);

    expect(reports.topProducts, isNotEmpty);
    for (int i = 1; i < reports.topProducts.length; i += 1) {
      expect(
        reports.topProducts[i - 1].revenue,
        greaterThanOrEqualTo(reports.topProducts[i].revenue),
      );
    }
  });

  test('تقرير الموظفين بيرجّع أداء كل كاشير', () async {
    if (skip()) return;

    await reports.selectReport(ReportType.employees);

    expect(reports.employeeRows, isNotEmpty);

    final EmployeeReportRow row = reports.employeeRows.first;
    expect(row.name, isNotEmpty);
    expect(row.invoices, greaterThan(0));
    expect(row.averageTicket, closeTo(row.sales / row.invoices, 0.01));
  });

  test('التقرير الضريبي بيفصل المحصّل عن المدفوع', () async {
    if (skip()) return;

    await reports.selectReport(ReportType.taxes);

    expect(reports.tax.taxRate, greaterThan(0));
    expect(reports.taxCollected, greaterThan(0));
    expect(reports.taxNet, closeTo(reports.taxCollected - reports.taxPaid, 0.01));
    expect(reports.monthlyTaxRows, isNotEmpty);

    final MonthlyTaxRow month = reports.monthlyTaxRows.first;
    expect(month.label, isNotEmpty);
    expect(month.tax, closeTo(month.taxableBase * reports.tax.taxRate, 1));
  });

  test('تقرير المخزون بيجمّع بالأقسام بقيمتين', () async {
    if (skip()) return;

    await reports.selectReport(ReportType.inventory);

    expect(reports.inventoryRows, isNotEmpty);
    expect(reports.inventoryTotalCost, greaterThan(0));
    expect(
      reports.inventoryTotalRetail,
      greaterThan(reports.inventoryTotalCost),
      reason: 'قيمة البيع أعلى من التكلفة',
    );

    final InventoryReportRow row = reports.inventoryRows.first;
    expect(row.name, isNotEmpty);
    expect(row.items, greaterThan(0));
    expect(row.expectedProfit, row.retail - row.cost);
  });

  test('تبديل التقرير بيعيد التحميل من غير فشل', () async {
    if (skip()) return;

    for (final ReportType type in ReportType.values) {
      await reports.selectReport(type);

      expect(reports.hasFailed, isFalse,
          reason: '${type.label}: ${reports.errorMessage}');
    }
  });

  test('الفروع بتتقرا مرة واحدة للفلتر', () async {
    if (skip()) return;

    await reports.load();
    expect(reports.branches, isNotEmpty);
    expect(reports.canSwitchBranch, isTrue, reason: 'المدير بيشوف كل الفروع');
  });

  test('المستخدم المقفول على فرع مبيقدرش يغيّره', () async {
    if (skip()) return;

    final ReportsController locked = ReportsController(
      ReportsRepository(api),
      vsync: const TestVSync(),
      lockedBranchId: 'b1',
    );

    expect(locked.canSwitchBranch, isFalse);
    expect(locked.branchId, 'b1');

    await locked.setBranch(null);
    expect(locked.branchId, 'b1', reason: 'التغيير ملازمش يعدّي');

    locked.dispose();
  });
}
