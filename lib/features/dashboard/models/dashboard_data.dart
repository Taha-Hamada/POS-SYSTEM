import '../../../core/models/product.dart';

/// كل أرقام الداشبورد في طلب واحد، زي ما السيرفر بيحسبها.
class DashboardData {
  const DashboardData({
    this.today = const PeriodStats(),
    this.period = const PeriodStats(),
    this.previous = const PeriodStats(),
    this.paymentMethods = const <String, double>{},
    this.series = const <SalesPoint>[],
    this.topProducts = const <TopProduct>[],
    this.lowStock = const <LowStockAlert>[],
    this.inventoryCostValue = 0,
    this.inventoryRetailValue = 0,
    this.outOfStockCount = 0,
    this.receivables = 0,
    this.payables = 0,
    this.expiringSoon = const <Product>[],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> inventory =
        (json['inventory'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> methods =
        (json['paymentMethods'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return DashboardData(
      today: PeriodStats.fromJson(json['today']),
      period: PeriodStats.fromJson(json['period']),
      previous: PeriodStats.fromJson(json['previous']),
      paymentMethods: <String, double>{
        for (final MapEntry<String, dynamic> entry in methods.entries)
          entry.key:
              _num((entry.value as Map<String, dynamic>?)?['amount']),
      },
      series: _list(json['series']).map(SalesPoint.fromJson).toList(),
      topProducts: _list(json['topProducts']).map(TopProduct.fromJson).toList(),
      lowStock: _list(json['lowStock']).map(LowStockAlert.fromJson).toList(),
      inventoryCostValue: _num(inventory['costValue']),
      inventoryRetailValue: _num(inventory['retailValue']),
      outOfStockCount: (inventory['outOfStock'] as num?)?.toInt() ?? 0,
      receivables: _num(
        (json['receivables'] as Map<String, dynamic>?)?['total'],
      ),
      payables: _num((json['payables'] as Map<String, dynamic>?)?['total']),
      expiringSoon: _list(json['expiringSoon']).map(Product.fromJson).toList(),
    );
  }

  final PeriodStats today;
  final PeriodStats period;

  /// نفس طول الفترة بس قبلها، عشان نحسب نسبة التغيّر.
  final PeriodStats previous;

  final Map<String, double> paymentMethods;
  final List<SalesPoint> series;
  final List<TopProduct> topProducts;
  final List<LowStockAlert> lowStock;

  final double inventoryCostValue;
  final double inventoryRetailValue;
  final int outOfStockCount;

  final double receivables;
  final double payables;
  final List<Product> expiringSoon;

  /// نسبة التغيّر عن الفترة السابقة. صفر سابق وقيمة حالية = 100%.
  static double changeBetween(double current, double previous) {
    if (previous == 0) return current == 0 ? 0 : 100;
    return ((current - previous) / previous) * 100;
  }

  double get salesChange => changeBetween(period.sales, previous.sales);
  double get profitChange => changeBetween(period.profit, previous.profit);

  double get invoicesChange => changeBetween(
        period.invoices.toDouble(),
        previous.invoices.toDouble(),
      );

  double get averageTicketChange =>
      changeBetween(period.averageTicket, previous.averageTicket);

  double get profitMargin =>
      period.sales == 0 ? 0 : (period.profit / period.sales) * 100;

  static double _num(dynamic value) => (value as num?)?.toDouble() ?? 0;

  static List<Map<String, dynamic>> _list(dynamic value) =>
      value is List<dynamic>
          ? value.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
}

/// إجماليات فترة واحدة.
class PeriodStats {
  const PeriodStats({
    this.sales = 0,
    this.invoices = 0,
    this.profit = 0,
    this.tax = 0,
    this.discounts = 0,
    this.returns = 0,
    this.expenses = 0,
    this.netProfit = 0,
    this.averageTicket = 0,
  });

  factory PeriodStats.fromJson(dynamic value) {
    if (value is! Map<String, dynamic>) return const PeriodStats();

    return PeriodStats(
      sales: DashboardData._num(value['sales']),
      invoices: (value['invoices'] as num?)?.toInt() ?? 0,
      profit: DashboardData._num(value['profit']),
      tax: DashboardData._num(value['tax']),
      discounts: DashboardData._num(value['discounts']),
      returns: DashboardData._num(value['returns']),
      expenses: DashboardData._num(value['expenses']),
      netProfit: DashboardData._num(value['netProfit']),
      averageTicket: DashboardData._num(value['averageTicket']),
    );
  }

  final double sales;
  final int invoices;
  final double profit;
  final double tax;
  final double discounts;
  final double returns;
  final double expenses;

  /// الربح بعد المرتجعات والمصروفات المعتمدة.
  final double netProfit;
  final double averageTicket;
}

/// نقطة يوم واحد في رسم المبيعات.
class SalesPoint {
  const SalesPoint({
    required this.date,
    required this.sales,
    required this.profit,
    required this.invoices,
  });

  factory SalesPoint.fromJson(Map<String, dynamic> json) => SalesPoint(
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        sales: DashboardData._num(json['sales']),
        profit: DashboardData._num(json['profit']),
        invoices: (json['invoices'] as num?)?.toInt() ?? 0,
      );

  final DateTime date;
  final double sales;
  final double profit;
  final int invoices;
}

class TopProduct {
  const TopProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.units,
    required this.revenue,
    required this.profit,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) => TopProduct(
        id: json['product'] as String? ?? '',
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        units: DashboardData._num(json['units']),
        revenue: DashboardData._num(json['revenue']),
        profit: DashboardData._num(json['profit']),
      );

  final String id;
  final String name;
  final String sku;
  final double units;
  final double revenue;
  final double profit;
}

/// صنف وصل لحد الطلب أو خلص.
class LowStockAlert {
  const LowStockAlert({
    required this.productName,
    required this.branchName,
    required this.quantity,
    required this.minStock,
    this.unit = '',
  });

  factory LowStockAlert.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> product =
        (json['product'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> branch =
        (json['branch'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return LowStockAlert(
      productName: product['name'] as String? ?? '',
      branchName: branch['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      minStock: (json['effectiveMinStock'] ?? json['minStock']) is num
          ? ((json['effectiveMinStock'] ?? json['minStock']) as num).toInt()
          : 0,
      unit: product['unit'] as String? ?? '',
    );
  }

  final String productName;
  final String branchName;
  final int quantity;
  final int minStock;
  final String unit;

  bool get isOut => quantity <= 0;
}

/// أداء فرع خلال الفترة.
class BranchStats {
  const BranchStats({
    required this.id,
    required this.name,
    required this.sales,
    required this.profit,
    required this.invoices,
    required this.share,
  });

  factory BranchStats.fromJson(Map<String, dynamic> json) => BranchStats(
        id: json['branch'] as String? ?? '',
        name: json['name'] as String? ?? '',
        sales: DashboardData._num(json['sales']),
        profit: DashboardData._num(json['profit']),
        invoices: (json['invoices'] as num?)?.toInt() ?? 0,
        share: DashboardData._num(json['share']),
      );

  final String id;
  final String name;
  final double sales;
  final double profit;
  final int invoices;

  /// نصيب الفرع من إجمالي المبيعات، بالنسبة المئوية.
  final double share;
}
