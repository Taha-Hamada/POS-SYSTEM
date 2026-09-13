import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// عنوان الـ API وإعداداته.
///
/// العنوان بيختلف حسب المنصة: محاكي أندرويد بيشوف جهاز الكمبيوتر على عنوان خاص
/// مش `localhost`، لأن `localhost` جوه المحاكي معناها المحاكي نفسه.
class ApiConfig {
  const ApiConfig._();

  /// ينفع تتجاوزه وقت التشغيل:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.5:5000`
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static const String _prefix = '/api/v1';

  static String get baseUrl {
    if (_override.isNotEmpty) return '$_override$_prefix';

    if (kIsWeb) return 'http://localhost:5000$_prefix';

    // محاكي أندرويد بيوصل لجهاز التطوير على 10.0.2.2 بس.
    if (Platform.isAndroid) return 'http://10.0.2.2:5000$_prefix';

    return 'http://localhost:5000$_prefix';
  }

  /// أي طلب بياخد أكتر من كده معناه إن السيرفر مش مستجيب.
  static const Duration timeout = Duration(seconds: 20);
}
