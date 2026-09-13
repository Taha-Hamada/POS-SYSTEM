import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/models/category.dart';
import 'package:pos_system/core/models/product.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/products_list/controllers/products_list_controller.dart';
import 'package:pos_system/features/products_list/data/products_repository.dart';
import 'package:pos_system/features/products_list/models/products_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة المنتجات وهي بتقرأ من الباك اند الحقيقي.
/// محتاج السيرفر شغال ومتعمله seed، وإلا الاختبارات بتتخطّى.
void main() {
  late ApiClient api;
  late ProductsListController controller;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();

    try {
      await api.get('/health');
      final SessionController session = SessionController(api);
      backendUp = await session.login(
        username: 'admin',
        password: 'Admin@12345',
      );
    } on ApiException {
      backendUp = false;
    }
  });

  setUp(() {
    controller = ProductsListController(ProductsRepository(api));
  });

  tearDown(() => controller.dispose());
  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  test('التحميل بيجيب منتجات وأقسام حقيقية', () async {
    if (skip()) return;

    expect(controller.isFirstLoad, isFalse);
    await controller.load();

    expect(controller.hasFailed, isFalse, reason: controller.errorMessage);
    expect(controller.isLoading, isFalse);
    expect(controller.rows, isNotEmpty, reason: 'محتاج npm run seed');
    expect(controller.categories, isNotEmpty);

    final Product product = controller.rows.first;
    expect(product.id, isNotEmpty);
    expect(product.name, isNotEmpty);
    expect(product.categoryName, isNot('—'),
        reason: 'القسم لازم يرجع مع المنتج');
  });

  test('البحث بيفلتر على الاسم والكود', () async {
    if (skip()) return;
    await controller.load();

    final Product target = controller.rows.first;
    controller.setQuery(target.sku);

    // البحث بيستنى شوية بعد آخر حرف.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(controller.rows, isNotEmpty);
    expect(
      controller.rows.every((Product p) =>
          p.sku.toLowerCase().contains(target.sku.toLowerCase())),
      isTrue,
    );

    controller.clearSearch();
    expect(controller.rows.length, greaterThan(1));
  });

  test('الفلترة بالقسم بترجع منتجات القسم بس', () async {
    if (skip()) return;
    await controller.load();

    final Category category = controller.categories
        .firstWhere((Category c) => c.productsCount > 0);

    controller.setCategory(category.id);

    expect(controller.rows, isNotEmpty);
    expect(
      controller.rows.every((Product p) => p.categoryId == category.id),
      isTrue,
    );
  });

  test('تبويب النواقص بيرجع اللي تحت الحد أو خلص', () async {
    if (skip()) return;
    await controller.load();

    controller.setFilter(ProductsFilter.lowStock);

    expect(
      controller.rows.every((Product p) => p.isLowStock || p.isOutOfStock),
      isTrue,
    );
    expect(controller.countFor(ProductsFilter.lowStock),
        controller.rows.length);
  });

  test('الأرصدة بتيجي مع المنتجات', () async {
    if (skip()) return;
    await controller.load();

    final Iterable<Product> tracked =
        controller.rows.where((Product p) => p.trackStock);

    expect(tracked, isNotEmpty);
    expect(tracked.any((Product p) => p.stock > 0), isTrue,
        reason: 'الـ seed بيحط أرصدة افتتاحية');
    expect(controller.visibleValue, greaterThan(0));
  });

  test('التعطيل بيتحفظ على السيرفر', () async {
    if (skip()) return;
    await controller.load();

    final Product target =
        controller.rows.firstWhere((Product p) => p.isActive);

    final String? error =
        await controller.setProductActive(target.id, isActive: false);
    expect(error, isNull);

    // بنعيد التحميل من السيرفر عشان نتأكد إن التغيير اتخزن مش في الذاكرة بس.
    final ProductsListController fresh =
        ProductsListController(ProductsRepository(api));
    await fresh.load();

    expect(
      fresh.rows.firstWhere((Product p) => p.id == target.id).isActive,
      isFalse,
    );

    await controller.setProductActive(target.id, isActive: true);
    fresh.dispose();
  });

  test('فشل الشبكة بيظهر كرسالة مش كانهيار', () async {
    final ApiClient broken = ApiClient();
    broken.setTokens(accessToken: 'x', refreshToken: 'y');

    final ProductsListController offline =
        ProductsListController(ProductsRepository(broken));

    // عنوان مش موجود بيقلّد سيرفر مقفول.
    await offline.load();

    expect(offline.hasFailed || offline.rows.isEmpty, isTrue);

    offline.dispose();
    broken.dispose();
  });
}
