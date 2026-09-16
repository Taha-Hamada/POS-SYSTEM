import '../../../core/api/api_client.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/store_settings.dart';

/// إعدادات الولاء وأرقام العملاء اللي شاشة الولاء بتعرضها.
class LoyaltyRepository {
  const LoyaltyRepository(this._api);

  final ApiClient _api;

  Future<StoreSettings> fetchSettings() async {
    final ApiResponse response = await _api.get('/settings');
    return StoreSettings.fromJson(response.object);
  }

  /// بيبعت الحقول المتغيرة بس. تغيير المستويات بيعيد حساب مستوى كل العملاء.
  Future<StoreSettings> saveSettings(Map<String, dynamic> changes) async {
    final ApiResponse response = await _api.patch('/settings', body: changes);
    return StoreSettings.fromJson(response.object);
  }

  /// أعلى العملاء رصيد نقاط.
  Future<List<Customer>> fetchTopCustomers({int limit = 10}) async {
    final ApiResponse response = await _api.get(
      '/customers',
      query: <String, dynamic>{
        'sort': '-points',
        'limit': limit,
        'isActive': 'true',
      },
    );

    // الترتيب بيتأكد هنا كمان عشان الجدول يفضل صح حتى لو الفرز اتغير.
    return response.list
        .map(Customer.fromJson)
        .where((Customer c) => c.points > 0)
        .toList()
      ..sort((Customer a, Customer b) => b.points.compareTo(a.points));
  }

  /// عدد العملاء في كل مستوى — صفحة بعنصر واحد كفاية لأن العدد في الترقيم.
  Future<Map<String, int>> fetchTierCounts(List<String> tiers) async {
    final List<int> counts = await Future.wait(<Future<int>>[
      for (final String tier in tiers)
        _api
            .get(
              '/customers',
              query: <String, dynamic>{'tier': tier, 'limit': 1},
            )
            .then((ApiResponse r) => r.total),
    ]);

    return <String, int>{
      for (int i = 0; i < tiers.length; i++) tiers[i]: counts[i],
    };
  }
}
