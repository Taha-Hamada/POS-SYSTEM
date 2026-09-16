import '../../../core/api/api_client.dart';
import '../../../core/models/store_settings.dart';

/// قراءة وحفظ إعدادات المتجر.
class SettingsRepository {
  const SettingsRepository(this._api);

  final ApiClient _api;

  Future<StoreSettings> fetch() async {
    final ApiResponse response = await _api.get('/settings');
    return StoreSettings.fromJson(response.object);
  }

  /// بيبعت الحقول اللي اتغيرت بس، عشان حفظ من شاشة مايرجّعش
  /// تعديل حد تاني عمله على حقل مختلف في نفس الوقت.
  Future<StoreSettings> update(Map<String, dynamic> changes) async {
    final ApiResponse response = await _api.patch('/settings', body: changes);
    return StoreSettings.fromJson(response.object);
  }
}
