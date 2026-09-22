import 'package:flutter/material.dart';

import '../../../core/api/load_state.dart';
import '../../dashboard/models/dashboard_data.dart';
import '../data/reports_repository.dart';
import '../models/report_period.dart';
import '../models/report_rows.dart';
import '../models/report_type.dart';

/// حالة شاشة التقارير: نوع التقرير والفترة والفرع المختارين.
///
/// الأرقام كلها محسوبة على السيرفر. الشاشة بتطلب التقرير المعروض بس،
/// عشان فتح الشاشة ما يجبش ستة تقارير مرة واحدة.
class ReportsController extends ChangeNotifier with LoadState {
  ReportsController(
    this._repository, {
    required TickerProvider vsync,
    this.lockedBranchId,
  }) {
    fadeController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );

    _branchId = lockedBranchId;
  }

  final ReportsRepository _repository;

  /// غير المدير بيشوف فرعه بس.
  final String? lockedBranchId;

  /// أنيميشن الـFade عند تبديل التقرير أو الفلاتر
  late final AnimationController fadeController;

  ReportType _type = ReportType.sales;
  ReportPeriod _period = ReportPeriod.month;
  String? _branchId;

  List<SalesPoint> _series = <SalesPoint>[];
  List<CategoryReportRow> _categories = <CategoryReportRow>[];
  List<TopProduct> _products = <TopProduct>[];
  List<EmployeeReportRow> _employees = <EmployeeReportRow>[];
  List<InventoryReportRow> _inventory = <InventoryReportRow>[];
  List<BranchStats> _branches = <BranchStats>[];
  TaxSummary _tax = const TaxSummary();

  ReportType get type => _type;
  ReportPeriod get period => _period;
  String? get branchId => _branchId;
  bool get canSwitchBranch => lockedBranchId == null;
  List<BranchStats> get branches => _branches;

  // ── التحميل ──────────────────────────────────────────────────────────────
  /// كل تقرير بيجيب اللي هو محتاجه بس.
  ///
  /// تقرير المبيعات والأرباح محتاجين السلسلة كمان عشان الرسم والإجماليات.
  Future<void> load() async {
    await runLoad(() async {
      // الفروع بتتقرا مرة واحدة عشان الفلتر، ومبتتغيّرش بتغيّر التقرير.
      if (_branches.isEmpty && canSwitchBranch) {
        _branches = await _repository.fetchBranches();
      }

      switch (_type) {
        case ReportType.sales:
          _series = await _fetchSeries();
        case ReportType.profit:
          final List<Object> results = await Future.wait(<Future<Object>>[
            _fetchSeries(),
            _repository.fetchByCategory(days: _period.days, branchId: _branchId),
          ]);
          _series = results[0] as List<SalesPoint>;
          _categories = results[1] as List<CategoryReportRow>;
        case ReportType.products:
          _products = await _repository.fetchTopProducts(
            days: _period.days,
            branchId: _branchId,
          );
        case ReportType.employees:
          final List<Object> results = await Future.wait(<Future<Object>>[
            _fetchSeries(),
            _repository.fetchCashiers(days: _period.days, branchId: _branchId),
          ]);
          _series = results[0] as List<SalesPoint>;
          _employees = results[1] as List<EmployeeReportRow>;
        case ReportType.taxes:
          _tax = await _repository.fetchTax(
            months: _monthsForPeriod,
            branchId: _branchId,
          );
        case ReportType.inventory:
          _inventory = await _repository.fetchInventory(branchId: _branchId);
      }
    });
  }

  Future<void> retry() => load();

  Future<List<SalesPoint>> _fetchSeries() =>
      _repository.fetchSeries(days: _period.days, branchId: _branchId);

  /// التقرير الضريبي شهري، فبنحوّل الفترة لعدد شهور.
  int get _monthsForPeriod => (_period.days / 30).ceil().clamp(1, 36);

  // ── إجراءات ──────────────────────────────────────────────────────────────
  /// بترجّع الـFuture عشان اللي بينادي يقدر يستنى التحميل لو محتاج.
  /// الواجهة بتنادي من غير انتظار، والاختبارات بتستنى.
  Future<void> selectReport(ReportType type) async {
    if (type == _type) return;
    _type = type;
    _replay();
    await load();
  }

  Future<void> setPeriod(ReportPeriod period) async {
    if (_period == period) return;
    _period = period;
    _replay();
    await load();
  }

  Future<void> setBranch(String? id) async {
    if (!canSwitchBranch || _branchId == id) return;
    _branchId = id;
    _replay();
    await load();
  }

  Future<void> refresh() async {
    _replay();
    await load();
  }

  /// إعادة بناء المحتوى مع إعادة تشغيل الـFade.
  void _replay() {
    fadeController
      ..reset()
      ..forward();
    notifyListeners();
  }

  // ── البيانات الأساسية ────────────────────────────────────────────────────
  List<SalesPoint> get series => _series;

  double get totalSales =>
      _series.fold<double>(0, (double s, SalesPoint p) => s + p.sales);

  double get totalProfit =>
      _series.fold<double>(0, (double s, SalesPoint p) => s + p.profit);

  int get totalInvoices =>
      _series.fold<int>(0, (int s, SalesPoint p) => s + p.invoices);

  double get avgInvoice =>
      totalInvoices == 0 ? 0 : totalSales / totalInvoices;

  double get avgDay => _series.isEmpty ? 0 : totalSales / _series.length;

  /// في الفترات الطويلة بنجمّع أسبوعيًا عشان الأعمدة تفضل مقروءة.
  bool get isWeeklyChart => _series.length > 45;

  List<SalesPoint> get chartPoints =>
      isWeeklyChart ? _groupWeekly(_series) : _series;

  List<SalesPoint> _groupWeekly(List<SalesPoint> series) {
    final List<SalesPoint> grouped = <SalesPoint>[];

    for (int i = 0; i < series.length; i += 7) {
      final List<SalesPoint> chunk =
          series.sublist(i, (i + 7).clamp(0, series.length));

      grouped.add(
        SalesPoint(
          date: chunk.first.date,
          sales: chunk.fold<double>(0, (double s, SalesPoint p) => s + p.sales),
          profit:
              chunk.fold<double>(0, (double s, SalesPoint p) => s + p.profit),
          invoices: chunk.fold<int>(0, (int s, SalesPoint p) => s + p.invoices),
        ),
      );
    }

    return grouped;
  }

  // ── تقارير بعينها ────────────────────────────────────────────────────────
  List<CategoryReportRow> get categoryRows => _categories;
  List<TopProduct> get topProducts => _products;
  List<EmployeeReportRow> get employeeRows => _employees;
  List<InventoryReportRow> get inventoryRows => _inventory;

  TaxSummary get tax => _tax;
  double get taxCharged => _tax.charged;

  /// الضريبة اللي رجعت للعملاء مع المرتجعات.
  double get taxRefunded => _tax.refunded;

  double get taxCollected => _tax.collected;
  double get taxPaid => _tax.paid;
  double get taxNet => _tax.net;
  List<MonthlyTaxRow> get monthlyTaxRows => _tax.months;

  double get inventoryTotalCost => _inventory.fold<double>(
        0,
        (double s, InventoryReportRow r) => s + r.cost,
      );

  double get inventoryTotalRetail => _inventory.fold<double>(
        0,
        (double s, InventoryReportRow r) => s + r.retail,
      );

  @override
  void dispose() {
    fadeController.dispose();
    super.dispose();
  }
}
