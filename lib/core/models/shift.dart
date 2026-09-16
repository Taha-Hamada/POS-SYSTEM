/// وردية كاشير جاية من الـ API.
class Shift {
  const Shift({
    required this.id,
    required this.number,
    required this.openingBalance,
    required this.openedAt,
    required this.isOpen,
    this.cashierName,
    this.branchId,
    this.branchName,
    this.closedAt,
    this.closing,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    final dynamic cashier = json['cashier'];
    final dynamic branch = json['branch'];
    final dynamic closing = json['closing'];

    return Shift(
      id: json['id'] as String,
      number: json['number'] as String? ?? '',
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
      openedAt:
          DateTime.tryParse(json['openedAt'] as String? ?? '') ??
          DateTime.now(),
      isOpen: json['status'] == 'open',
      cashierName: cashier is Map<String, dynamic>
          ? cashier['name'] as String?
          : null,
      branchId: branch is Map<String, dynamic>
          ? branch['id'] as String?
          : branch as String?,
      branchName: branch is Map<String, dynamic>
          ? branch['name'] as String?
          : null,
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.tryParse(json['closedAt'] as String),
      closing: closing is Map<String, dynamic> && closing['countedCash'] != null
          ? ShiftClosing.fromJson(closing)
          : null,
    );
  }

  final String id;
  final String number;
  final double openingBalance;
  final DateTime openedAt;
  final bool isOpen;
  final String? cashierName;

  /// فرع الوردية — الحساب اللي مش مربوط بفرع بيبيع فيه.
  final String? branchId;
  final String? branchName;
  final DateTime? closedAt;

  /// أرقام التقفيل المتجمّدة — موجودة بعد الإغلاق بس.
  final ShiftClosing? closing;

  Duration get elapsed => (closedAt ?? DateTime.now()).difference(openedAt);
}

/// أرقام الوردية اللحظية، محسوبة على السيرفر من الفواتير والمرتجعات.
class ShiftTotals {
  const ShiftTotals({
    this.salesTotal = 0,
    this.invoicesCount = 0,
    this.profit = 0,
    this.taxTotal = 0,
    this.discountTotal = 0,
    this.returnsTotal = 0,
    this.cashRefunds = 0,
    this.cashExpenses = 0,
    this.cashSales = 0,
    this.cashIn = 0,
    this.cashOut = 0,
    this.expectedCash = 0,
    this.byMethod = const <String, double>{},
  });

  factory ShiftTotals.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> methods =
        (json['byMethod'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return ShiftTotals(
      salesTotal: _num(json['salesTotal']),
      invoicesCount: (json['invoicesCount'] as num?)?.toInt() ?? 0,
      profit: _num(json['profit']),
      taxTotal: _num(json['taxTotal']),
      discountTotal: _num(json['discountTotal']),
      returnsTotal: _num(json['returnsTotal']),
      cashRefunds: _num(json['cashRefunds']),
      cashExpenses: _num(json['cashExpenses']),
      cashSales: _num(json['cashSales']),
      cashIn: _num(json['cashIn']),
      cashOut: _num(json['cashOut']),
      expectedCash: _num(json['expectedCash']),
      byMethod: <String, double>{
        for (final MapEntry<String, dynamic> entry in methods.entries)
          entry.key: _num((entry.value as Map<String, dynamic>?)?['amount']),
      },
    );
  }

  static double _num(dynamic value) => (value as num?)?.toDouble() ?? 0;

  final double salesTotal;
  final int invoicesCount;
  final double profit;
  final double taxTotal;
  final double discountTotal;
  final double returnsTotal;
  final double cashRefunds;
  final double cashExpenses;
  final double cashSales;
  final double cashIn;
  final double cashOut;

  /// المفروض يكون في الدرج دلوقتي، محسوب على السيرفر.
  final double expectedCash;

  final Map<String, double> byMethod;

  double methodTotal(String method) => byMethod[method] ?? 0;

  double get cardSales => methodTotal('card');
  double get walletSales => methodTotal('wallet');
  double get creditSales => methodTotal('credit');
}

/// نتيجة تقفيل الوردية.
class ShiftClosing {
  const ShiftClosing({
    required this.countedCash,
    required this.expectedCash,
    required this.difference,
    required this.salesTotal,
    required this.invoicesCount,
    this.note = '',
  });

  factory ShiftClosing.fromJson(Map<String, dynamic> json) => ShiftClosing(
    countedCash: ShiftTotals._num(json['countedCash']),
    expectedCash: ShiftTotals._num(json['expectedCash']),
    difference: ShiftTotals._num(json['difference']),
    salesTotal: ShiftTotals._num(json['salesTotal']),
    invoicesCount: (json['invoicesCount'] as num?)?.toInt() ?? 0,
    note: json['note'] as String? ?? '',
  );

  final double countedCash;
  final double expectedCash;

  /// موجب = زيادة في الدرج، سالب = عجز.
  final double difference;
  final double salesTotal;
  final int invoicesCount;
  final String note;

  bool get isBalanced => difference.abs() < 0.005;
  bool get isShort => difference < 0;
}
