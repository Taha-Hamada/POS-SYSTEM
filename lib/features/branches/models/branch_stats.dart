import '../../../core/models/branch.dart';

/// فرع بأرقامه اللي بتظهر على بطاقته.
class BranchStats {
  const BranchStats({
    required this.branch,
    this.todaySales = 0,
    this.todayInvoices = 0,
    this.monthSales = 0,
  });

  factory BranchStats.fromJson(Map<String, dynamic> json) => BranchStats(
    branch: Branch.fromJson(json),
    todaySales: (json['todaySales'] as num?)?.toDouble() ?? 0,
    todayInvoices: (json['todayInvoices'] as num?)?.toInt() ?? 0,
    monthSales: (json['monthSales'] as num?)?.toDouble() ?? 0,
  );

  final Branch branch;
  final double todaySales;
  final int todayInvoices;
  final double monthSales;
}

/// إجماليات كل الفروع ومعاها الفترة اللي فاتت للمقارنة.
class BranchesTotals {
  const BranchesTotals({
    this.branches = 0,
    this.open = 0,
    this.todaySales = 0,
    this.yesterdaySales = 0,
    this.monthSales = 0,
    this.lastMonthSales = 0,
  });

  factory BranchesTotals.fromJson(Map<String, dynamic> json) => BranchesTotals(
    branches: (json['branches'] as num?)?.toInt() ?? 0,
    open: (json['open'] as num?)?.toInt() ?? 0,
    todaySales: (json['todaySales'] as num?)?.toDouble() ?? 0,
    yesterdaySales: (json['yesterdaySales'] as num?)?.toDouble() ?? 0,
    monthSales: (json['monthSales'] as num?)?.toDouble() ?? 0,
    lastMonthSales: (json['lastMonthSales'] as num?)?.toDouble() ?? 0,
  );

  final int branches;
  final int open;
  final double todaySales;
  final double yesterdaySales;
  final double monthSales;

  /// نفس عدد الأيام من الشهر اللي فات، مش الشهر كله.
  final double lastMonthSales;

  /// null لما مفيش أرقام قبلها نقارن بيها — نسبة من صفر مالهاش معنى.
  double? get todayChange => _change(todaySales, yesterdaySales);
  double? get monthChange => _change(monthSales, lastMonthSales);

  static double? _change(double current, double previous) =>
      previous <= 0 ? null : ((current - previous) / previous) * 100;
}

/// بيانات فرع جديد أو تعديل فرع موجود.
class BranchInput {
  const BranchInput({
    required this.name,
    required this.code,
    this.address = '',
    this.phone = '',
    this.openFrom = '09:00',
    this.openTo = '23:00',
  });

  final String name;
  final String code;
  final String address;
  final String phone;
  final String openFrom;
  final String openTo;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'code': code,
    'address': address,
    'phone': phone,
    'openingHours': <String, String>{'from': openFrom, 'to': openTo},
  };
}
