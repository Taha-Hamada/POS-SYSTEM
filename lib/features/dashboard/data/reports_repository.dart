import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/dashboard_data.dart';

/// قراءة التقارير من الـ API.
class ReportsRepository {
  const ReportsRepository(this._api);

  final ApiClient _api;

  /// كل أرقام الداشبورد في طلب واحد.
  Future<DashboardData> fetchDashboard({int days = 30, String? branchId}) async {
    final ApiResponse response = await _api.get(
      '/reports/dashboard',
      query: <String, dynamic>{'days': days, 'branch': branchId},
    );

    return DashboardData.fromJson(response.object);
  }

  /// مقارنة الفروع.
  ///
  /// مقصورة على اللي بيشوف الفروع، فبترجّع قايمة فاضية بدل ما ترمي خطأ
  /// لما الكاشير أو أمين المخزن يفتح الشاشة.
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
}
