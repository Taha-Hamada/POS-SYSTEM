import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/store_settings.dart';

/// إعدادات المتجر على مستوى التطبيق كله.
///
/// الضريبة والعملة وسياسات البيع بتتقرا مرة واحدة بعد الدخول،
/// بدل ما كل شاشة محتاجاها تطلبها لوحدها.
class SettingsController extends ChangeNotifier {
  SettingsController(this._api);

  final ApiClient _api;

  StoreSettings _settings = const StoreSettings();
  bool _loaded = false;
  bool _disposed = false;

  StoreSettings get settings => _settings;
  bool get isLoaded => _loaded;

  double get taxRate => _settings.taxRate;
  String get currency => _settings.currency;

  Future<void> load() async {
    try {
      final ApiResponse response = await _api.get('/settings');
      // الـShell ممكن يتقفل (تسجيل خروج) والطلب لسه راجع.
      if (_disposed) return;
      _settings = StoreSettings.fromJson(response.object);
      _loaded = true;
      notifyListeners();
    } on ApiException {
      // القيم الافتراضية بتفضل شغالة؛ الشاشات مبتقفش على الإعدادات.
    }
  }

  /// بتتنادى بعد ما الإعدادات تتحفظ من شاشة الإعدادات.
  void apply(StoreSettings settings) {
    _settings = settings;
    _loaded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
