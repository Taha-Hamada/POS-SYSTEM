import '../../../core/api/api_client.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/payment_method.dart';

/// صفحة من المصروفات مع عددها الكلي على السيرفر.
typedef ExpensesPage = ({List<Expense> items, int total});

/// بند مصروف بإجماليه ونصيبه من الكل.
typedef ExpenseCategoryTotal = ({
  String category,
  double total,
  int count,
  double share,
});

/// تفصيل المصروفات ببنودها.
typedef ExpensesSummary = ({double total, List<ExpenseCategoryTotal> categories});

/// قراءة وكتابة المصروفات من الـ API.
class ExpensesRepository {
  const ExpensesRepository(this._api);

  final ApiClient _api;

  /// الفلترة والفرز والصفحات كلها على السيرفر، عشان الأرقام اللي تحت الجدول
  /// تبقى للفلتر كله مش للصفحة المعروضة.
  Future<ExpensesPage> fetchPage({
    int page = 1,
    int limit = 50,
    String? search,
    String? category,
    String? branchId,
    ExpenseStatus? status,
    DateTime? from,
    DateTime? to,
    String sort = '-date',
  }) async {
    final ApiResponse response = await _api.get(
      '/expenses',
      query: <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort': sort,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'category': category,
        'branch': branchId,
        'status': status?.apiValue,
        'from': from?.toIso8601String(),
        'to': to?.toIso8601String(),
      },
    );

    return (
      items: response.list.map(Expense.fromJson).toList(),
      total: response.total,
    );
  }

  Future<ExpensesSummary> fetchSummary({
    String? branchId,
    ExpenseStatus? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final ApiResponse response = await _api.get(
      '/expenses/summary',
      query: <String, dynamic>{
        'branch': branchId,
        'status': status?.apiValue,
        'from': from?.toIso8601String(),
        'to': to?.toIso8601String(),
      },
    );

    final Map<String, dynamic> data = response.object;
    final List<dynamic> rows = data['categories'] as List<dynamic>? ?? <dynamic>[];

    return (
      total: (data['total'] as num?)?.toDouble() ?? 0,
      categories: rows
          .cast<Map<String, dynamic>>()
          .map((Map<String, dynamic> row) => (
                category: row['category'] as String? ?? '',
                total: (row['total'] as num?)?.toDouble() ?? 0,
                count: (row['count'] as num?)?.toInt() ?? 0,
                share: (row['share'] as num?)?.toDouble() ?? 0,
              ))
          .toList(growable: false),
    );
  }

  Future<Expense> create({
    required String category,
    required double amount,
    required PaymentMethod paymentMethod,
    String? branchId,
    DateTime? date,
    String? note,
  }) async {
    final ApiResponse response = await _api.post(
      '/expenses',
      body: <String, dynamic>{
        'category': category,
        'amount': amount,
        'paymentMethod': paymentMethod.apiValue,
        'branch': ?branchId,
        'date': ?date?.toIso8601String(),
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return Expense.fromJson(response.object);
  }

  /// الاعتماد والرفض ليهم مسار واحد على السيرفر، والرفض لازم له سبب.
  Future<Expense> review(
    String id, {
    required bool approve,
    String? reason,
  }) async {
    final ApiResponse response = await _api.post(
      '/expenses/$id/review',
      body: <String, dynamic>{
        'approve': approve,
        if (!approve) 'reason': reason,
      },
    );

    return Expense.fromJson(response.object);
  }

  Future<void> delete(String id) => _api.delete('/expenses/$id');
}
