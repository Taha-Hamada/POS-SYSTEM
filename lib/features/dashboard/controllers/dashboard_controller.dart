import 'package:flutter/material.dart';

import '../../../core/api/load_state.dart';
import '../../../theme/app_theme.dart';
import '../data/reports_repository.dart';
import '../models/dashboard_data.dart';
import '../models/dashboard_period.dart';
import '../models/payment_slice.dart';

/// حالة لوحة التحكم: الفترة الزمنية والفرع المختارين، والأرقام الجاية من السيرفر.
///
/// كل الحسابات بتتعمل على السيرفر ومنها المقارنة بالفترة السابقة، فالشاشة
/// بتعرض بس. طلب واحد بيجيب أرقام الصفحة كلها.
class DashboardController extends ChangeNotifier with LoadState {
  DashboardController(
    this._repository, {
    required TickerProvider vsync,
    this.lockedBranchId,
  }) {
    entryController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _branchId = lockedBranchId;
  }

  final ReportsRepository _repository;

  /// غير المدير بيشوف فرعه بس، فالفلتر بيتقفل عليه.
  final String? lockedBranchId;

  /// أنيميشن الدخول المتدرّج لكل عناصر الصفحة
  late final AnimationController entryController;

  DashboardPeriod _period = DashboardPeriod.month;
  String? _branchId;

  DashboardData _data = const DashboardData();
  List<BranchStats> _branches = <BranchStats>[];

  DashboardPeriod get period => _period;
  String? get branchId => _branchId;
  DashboardData get data => _data;
  List<BranchStats> get branchesPerformance => _branches;

  bool get canSwitchBranch => lockedBranchId == null;

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchDashboard(days: _period.days, branchId: _branchId),
        _repository.fetchBranches(),
      ]);

      _data = results[0] as DashboardData;
      _branches = results[1] as List<BranchStats>;
    });
  }

  Future<void> retry() => load();

  void setPeriod(DashboardPeriod period) {
    if (_period == period) return;
    _period = period;
    notifyListeners();
    load();
  }

  void setBranch(String? id) {
    if (!canSwitchBranch || _branchId == id) return;
    _branchId = id;
    notifyListeners();
    load();
  }

  // ── أرقام الفترة الحالية ─────────────────────────────────────────────────
  double get sales => _data.period.sales;
  double get profit => _data.period.profit;
  int get invoices => _data.period.invoices;
  double get avgInvoice => _data.period.averageTicket;
  double get profitMargin => _data.profitMargin;

  // ── نِسَب التغيّر عن الفترة السابقة ───────────────────────────────────────
  double get salesChange => _data.salesChange;
  double get profitChange => _data.profitChange;
  double get invoicesChange => _data.invoicesChange;
  double get avgInvoiceChange => _data.averageTicketChange;

  // ── بيانات الرسوم والجداول ───────────────────────────────────────────────
  List<SalesPoint> get current => _data.series;

  List<PaymentSlice> get paymentSlices => <PaymentSlice>[
        PaymentSlice(
          label: 'كاش',
          value: _data.paymentMethods['cash'] ?? 0,
          color: AppColors.success,
          icon: Icons.payments_rounded,
        ),
        PaymentSlice(
          label: 'بطاقة',
          value: _data.paymentMethods['card'] ?? 0,
          color: AppColors.info,
          icon: Icons.credit_card_rounded,
        ),
        PaymentSlice(
          label: 'محفظة',
          value: _data.paymentMethods['wallet'] ?? 0,
          color: AppColors.accent,
          icon: Icons.account_balance_wallet_rounded,
        ),
        PaymentSlice(
          label: 'آجل',
          value: _data.paymentMethods['credit'] ?? 0,
          color: AppColors.warning,
          icon: Icons.schedule_rounded,
        ),
      ];

  List<TopProduct> get topProducts => _data.topProducts;

  List<LowStockAlert> get lowStock => _data.lowStock;

  /// الشاشة فاضية لما الفترة مفيهاش أي فاتورة.
  bool get isEmpty => !isLoading && !hasFailed && _data.period.invoices == 0;

  @override
  void dispose() {
    entryController.dispose();
    super.dispose();
  }
}
