import '../../../core/api/api_client.dart';
import '../../../core/models/branch.dart';
import '../models/branch_stats.dart';

typedef BranchesOverview = ({
  List<BranchStats> branches,
  BranchesTotals totals,
});

/// إدارة الفروع: الأرقام والإضافة والتعديل والفتح والتعطيل.
///
/// قراءة قايمة الفروع للفلاتر في [BranchesRepository] المشتركة،
/// والملف ده خاص بشاشة الفروع نفسها.
class BranchManagementRepository {
  const BranchManagementRepository(this._api);

  final ApiClient _api;

  Future<BranchesOverview> fetchOverview() async {
    final ApiResponse response = await _api.get('/branches/overview');
    final Map<String, dynamic> data = response.object;

    return (
      branches: (data['branches'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(BranchStats.fromJson)
          .toList(growable: false),
      totals: BranchesTotals.fromJson(
        data['totals'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }

  Future<Branch> create(BranchInput input) async {
    final ApiResponse response = await _api.post(
      '/branches',
      body: input.toJson(),
    );
    return Branch.fromJson(response.object);
  }

  Future<Branch> update(String id, BranchInput input) async {
    final ApiResponse response = await _api.patch(
      '/branches/$id',
      body: input.toJson(),
    );
    return Branch.fromJson(response.object);
  }

  Future<Branch> setOpen(String id, {required bool isOpen}) async {
    final ApiResponse response = await _api.patch(
      '/branches/$id/open-state',
      body: <String, bool>{'isOpen': isOpen},
    );
    return Branch.fromJson(response.object);
  }

  /// السيرفر مبيمسحش الفرع لأن الفواتير مربوطة بيه، بيعطّله بس.
  Future<void> deactivate(String id) => _api.delete('/branches/$id');
}
