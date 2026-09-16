import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/models/store_settings.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/settings/controllers/settings_controller.dart';
import 'package:pos_system/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Vsync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

/// شاشة الإعدادات وهي بتقرا وتحفظ على الباك اند الحقيقي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // الـbinding بيحجب الشبكة، والاختبار ده بيضرب السيرفر فعلًا.
  HttpOverrides.global = null;

  late ApiClient api;
  late SettingsRepository repository;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();
    repository = SettingsRepository(api);

    try {
      await api.get('/health');
      backendUp = await SessionController(
        api,
      ).login(username: 'admin', password: 'Admin@12345');
    } on ApiException {
      backendUp = false;
    }
  });

  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  test('بيحفظ الحقول المتغيرة بس ويرجع القيم زي ما كانت', () async {
    if (skip()) return;

    final SettingsController controller = SettingsController(
      repository,
      vsync: _Vsync(),
      canEdit: true,
    );
    await controller.load();

    final StoreSettings original = controller.saved;
    expect(controller.dirty, isFalse);

    try {
      controller.storePhoneController.text = '0100${DateTime.now().second}';
      controller.taxRateController.text = '12.5';
      controller.setReceiptWidth(58);
      expect(controller.dirty, isTrue);

      expect(await controller.save(), isNull);
      expect(controller.dirty, isFalse);

      final StoreSettings reloaded = await repository.fetch();
      expect(reloaded.taxRate, closeTo(0.125, 0.0001));
      expect(reloaded.receiptWidthMm, 58);
      expect(reloaded.storeName, original.storeName);

      // نسبة برّه الحدود بتترفض قبل ما تتبعت.
      controller.taxRateController.text = '150';
      expect(await controller.save(), isNotNull);
    } finally {
      await repository.update(<String, dynamic>{
        'storePhone': original.storePhone,
        'taxRate': original.taxRate,
        'receiptWidthMm': original.receiptWidthMm,
      });
    }

    controller.dispose();
  });
}
