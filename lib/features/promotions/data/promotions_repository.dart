import '../../../core/api/api_client.dart';
import '../../../core/models/promotion.dart';
import '../models/promotion_input.dart';

/// قراءة وكتابة العروض من الـ API.
class PromotionsRepository {
  const PromotionsRepository(this._api);

  final ApiClient _api;

  /// كل العروض — الشاشة بتفلتر بالحالة محليًا عشان العدّادات تبقى للكل.
  Future<List<Promotion>> fetchAll() async {
    final List<Promotion> all = <Promotion>[];
    int page = 1;

    while (true) {
      final ApiResponse response = await _api.get(
        '/promotions',
        query: <String, dynamic>{
          'page': page,
          'limit': 100,
          'sort': '-startsAt',
        },
      );

      all.addAll(response.list.map(Promotion.fromJson));
      if (!response.hasNext) break;
      page++;
    }

    return all;
  }

  Future<Promotion> create(PromotionInput input) async {
    final ApiResponse response = await _api.post(
      '/promotions',
      body: input.toJson(),
    );
    return Promotion.fromJson(response.object);
  }

  Future<Promotion> update(String id, PromotionInput input) async {
    final ApiResponse response = await _api.patch(
      '/promotions/$id',
      body: input.toJson(),
    );
    return Promotion.fromJson(response.object);
  }

  /// الإيقاف بيشيل العرض من الفواتير الجاية ويسيبه في السجل.
  Future<Promotion> setActive(String id, {required bool isActive}) async {
    final ApiResponse response = await _api.patch(
      '/promotions/$id/active',
      body: <String, bool>{'isActive': isActive},
    );
    return Promotion.fromJson(response.object);
  }
}
