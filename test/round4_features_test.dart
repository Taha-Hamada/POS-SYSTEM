import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/data/branches_repository.dart';
import 'package:pos_system/core/models/branch.dart';
import 'package:pos_system/core/models/category.dart';
import 'package:pos_system/core/models/product.dart';
import 'package:pos_system/core/models/shift.dart';
import 'package:pos_system/core/models/store_settings.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/cashier_shift/controllers/current_shift_controller.dart';
import 'package:pos_system/features/cashier_shift/data/shift_repository.dart';
import 'package:pos_system/features/products_list/data/products_repository.dart';
import 'package:pos_system/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// حركة الكاش، صورة المنتج، صلاحيات الموظف، وتنبيهات الإعدادات
/// على الباك اند الحقيقي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // الـbinding بيحجب الشبكة، والاختبار ده بيضرب السيرفر فعلًا.
  HttpOverrides.global = null;

  late ApiClient api;
  bool backendUp = false;

  /// صورة PNG 1×1 — أصغر ملف صورة صالح.
  final Uint8List png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();

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

  String unique() => DateTime.now().millisecondsSinceEpoch.toString();

  test('الإيداع والسحب بيغيّروا المتوقع في الدرج', () async {
    if (skip()) return;

    final ShiftRepository repository = ShiftRepository(api);
    final CurrentShiftController shifts = CurrentShiftController(repository);
    final Branch branch = (await BranchesRepository(api).fetchAll()).first;

    await shifts.load();
    if (shifts.isOpen) await shifts.close(countedCash: 0);

    expect(await shifts.open(500, branchId: branch.id), isNull);

    try {
      final double before = shifts.totals.expectedCash;

      expect(
        await shifts.addCash(isIn: true, amount: 200, reason: 'فكة للدرج'),
        isNull,
      );
      expect(shifts.totals.cashIn, 200);
      expect(shifts.totals.expectedCash, before + 200);

      expect(
        await shifts.addCash(isIn: false, amount: 50, reason: 'توريد للخزنة'),
        isNull,
      );
      expect(shifts.totals.cashOut, 50);
      expect(shifts.totals.expectedCash, before + 150);

      // السحب الغلط بيترفض من السيرفر.
      expect(
        await shifts.addCash(isIn: true, amount: 0, reason: 'صفر'),
        isNotNull,
      );
    } finally {
      final Shift? open = shifts.shift;
      if (open != null) {
        await repository.close(
          open.id,
          countedCash: shifts.totals.expectedCash,
        );
      }
      shifts.dispose();
    }
  });

  test('رفع صورة المنتج وحذفها', () async {
    if (skip()) return;

    final ProductsRepository products = ProductsRepository(api);
    final List<Category> categories = await products.fetchCategories();

    final Product created = await products.create(
      name: 'منتج صورة ${unique()}',
      sku: 'IMG-${unique()}',
      categoryId: categories.first.id,
      price: 20,
      cost: 10,
    );

    try {
      final Product withImage = await products.uploadImage(
        created.id,
        bytes: png,
        filename: 'tiny.png',
      );
      expect(withImage.imageUrl, startsWith('/uploads/products/'));

      // الصورة بتتخدم فعلًا من السيرفر.
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(
        Uri.parse('${ApiConfig.origin}${withImage.imageUrl}'),
      );
      final HttpClientResponse response = await request.close();
      expect(response.statusCode, 200);
      expect(response.headers.contentType?.mimeType, 'image/png');
      client.close();

      // ملف مش صورة بيترفض.
      await expectLater(
        products.uploadImage(
          created.id,
          bytes: Uint8List.fromList(utf8.encode('not an image')),
          filename: 'fake.png',
        ),
        throwsA(isA<ApiException>()),
      );

      final Product cleared = await products.removeImage(created.id);
      expect(cleared.imageUrl, isNull);
    } finally {
      await products.setActiveState(created.id, isActive: false);
    }
  });

  test('تنبيهات الإعدادات بتتحفظ على السيرفر', () async {
    if (skip()) return;

    final SettingsRepository settings = SettingsRepository(api);
    final StoreSettings before = await settings.fetch();

    try {
      final StoreSettings saved = await settings.update(<String, dynamic>{
        'notifications': <String, bool>{'lowStock': false, 'expiry': true},
      });

      expect(saved.notifyLowStock, isFalse);
      expect(saved.notifyExpiry, isTrue);
      expect((await settings.fetch()).notifyLowStock, isFalse);
    } finally {
      await settings.update(<String, dynamic>{
        'notifications': <String, bool>{
          'lowStock': before.notifyLowStock,
          'expiry': before.notifyExpiry,
        },
      });
    }
  });
}
