import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/branch.dart';

/// قراءة الفروع من الـ API.
class BranchesRepository {
  const BranchesRepository(this._api);

  final ApiClient _api;

  /// الفروع النشطة المتاحة للفلاتر.
  ///
  /// بعض الأدوار (زي أمين المخزن) مبتشوفش قائمة الفروع، فبترجّع فاضية
  /// بدل ما ترمي خطأ يقفل الشاشة كلها، والشاشة بتقفل على فرع المستخدم.
  Future<List<Branch>> fetchAll() async {
    try {
      final ApiResponse response = await _api.get(
        '/branches',
        query: <String, dynamic>{'limit': 100, 'isActive': 'true'},
      );

      return response.list.map(Branch.fromJson).toList();
    } on ApiException catch (exception) {
      if (exception.isForbidden) return <Branch>[];
      rethrow;
    }
  }
}
