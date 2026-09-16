import '../../../core/api/api_client.dart';
import '../models/return_record.dart';

typedef ReturnsPage = ({List<ReturnRecord> items, int total});
typedef ReturnsSummary = ({int count, double total});

/// قراءة سجل المرتجعات.
class ReturnsHistoryRepository {
  const ReturnsHistoryRepository(this._api);

  final ApiClient _api;

  Future<ReturnsPage> fetchPage({
    DateTime? from,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    final ApiResponse response = await _api.get(
      '/returns',
      query: <String, dynamic>{
        'page': page,
        'limit': limit,
        'from': from?.toUtc().toIso8601String(),
        'search': search,
      },
    );

    return (
      items: response.list.map(ReturnRecord.fromJson).toList(),
      total: response.total,
    );
  }

  /// الإجماليات للفترة كلها مش للصفحة المعروضة.
  Future<ReturnsSummary> fetchSummary({DateTime? from}) async {
    final ApiResponse response = await _api.get(
      '/returns/summary',
      query: <String, dynamic>{'from': from?.toUtc().toIso8601String()},
    );

    return (
      count: (response.object['returnsCount'] as num?)?.toInt() ?? 0,
      total: (response.object['total'] as num?)?.toDouble() ?? 0,
    );
  }

  /// المرتجع بسطوره.
  Future<ReturnRecord> fetchOne(String id) async {
    final ApiResponse response = await _api.get('/returns/$id');
    return ReturnRecord.fromJson(response.object);
  }
}
