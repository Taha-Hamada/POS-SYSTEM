import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../dashboard/models/dashboard_data.dart';
import '../models/report_rows.dart';

/// قراءة تقارير الشاشة من الـ API.
///
/// كل نوع تقرير له مسار، والشاشة بتطلب اللي معروض بس مش كل التقارير.
class ReportsRepository {
  const ReportsRepository(this._api);

  final ApiClient _api;

  Map<String, dynamic> _period({
    required int days,
    String? branchId,
  }) {
    final DateTime from = DateTime.now().subtract(Duration(days: days - 1));

    return <String, dynamic>{
      'from': DateTime(from.year, from.month, from.day).toIso8601String(),
      'branch': branchId,
    };
  }

  /// الفروع المتاحة للفلتر — بترجّع فاضية لو المستخدم مش بيشوف الفروع.
  Future<List<BranchStats>> fetchBranches() async {
    try {
      final ApiResponse response = await _api.get('/reports/branches');

      final List<dynamic> branches =
          (response.object['branches'] as List<dynamic>?) ?? <dynamic>[];

      return branches
          .whereType<Map<String, dynamic>>()
          .map(BranchStats.fromJson)
          .toList();
    } on ApiException catch (exception) {
      if (exception.isForbidden) return <BranchStats>[];
      rethrow;
    }
  }

  Future<List<SalesPoint>> fetchSeries({
    required int days,
    String? branchId,
  }) async {
    final ApiResponse response = await _api.get(
      '/reports/sales-series',
      query: <String, dynamic>{'days': days, 'branch': branchId},
    );

    return response.list.map(SalesPoint.fromJson).toList();
  }

  Future<List<CategoryReportRow>> fetchByCategory({
    required int days,
    String? branchId,
  }) async {
    final ApiResponse response = await _api.get(
      '/reports/by-category',
      query: _period(days: days, branchId: branchId),
    );

    final List<dynamic> rows =
        (response.object['categories'] as List<dynamic>?) ?? <dynamic>[];

    return rows
        .whereType<Map<String, dynamic>>()
        .map(CategoryReportRow.fromJson)
        .toList();
  }

  Future<List<TopProduct>> fetchTopProducts({
    required int days,
    String? branchId,
    int limit = 20,
  }) async {
    final ApiResponse response = await _api.get(
      '/reports/top-products',
      query: <String, dynamic>{
        ..._period(days: days, branchId: branchId),
        'limit': limit,
      },
    );

    return response.list.map(TopProduct.fromJson).toList();
  }

  Future<List<EmployeeReportRow>> fetchCashiers({
    required int days,
    String? branchId,
  }) async {
    final ApiResponse response = await _api.get(
      '/reports/cashiers',
      query: _period(days: days, branchId: branchId),
    );

    return response.list.map(EmployeeReportRow.fromJson).toList();
  }

  Future<TaxSummary> fetchTax({required int months, String? branchId}) async {
    final ApiResponse response = await _api.get(
      '/reports/tax',
      query: <String, dynamic>{'months': months, 'branch': branchId},
    );

    return TaxSummary.fromJson(response.object);
  }

  Future<List<InventoryReportRow>> fetchInventory({String? branchId}) async {
    final ApiResponse response = await _api.get(
      '/reports/inventory-by-category',
      query: <String, dynamic>{'branch': branchId},
    );

    return response.list.map(InventoryReportRow.fromJson).toList();
  }
}
