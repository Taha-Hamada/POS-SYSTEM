import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/models/category.dart';
import 'package:pos_system/core/models/product.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/add_edit_product/controllers/product_form_controller.dart';
import 'package:pos_system/features/add_edit_product/models/product_variant.dart';
import 'package:pos_system/features/products_list/data/products_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نموذج إضافة المنتج وهو بيكتب على الباك اند الحقيقي.
void main() {
  // الكنترولر جواه TabController، وده محتاج binding شغال.
  TestWidgetsFlutterBinding.ensureInitialized();

  // الـbinding بيحجب الشبكة، والاختبار ده بيضرب السيرفر فعلًا.
  HttpOverrides.global = null;

  late ApiClient api;
  late ProductsRepository repository;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();
    repository = ProductsRepository(api);

    try {
      await api.get('/health');
      final SessionController auth = SessionController(api);
      backendUp = await auth.login(
        username: 'admin',
        password: 'Admin@12345',
      );
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

  /// كود فريد لكل اختبار عشان المحاولات المتكررة ما تتصادمش.
  String uniqueSku() =>
      'TST-${DateTime.now().microsecondsSinceEpoch.remainder(100000000)}';

  // TabController محتاج vsync، و TestVSync بيقدّمه من غير شجرة ودجتس.
  ProductFormController newForm({String? branchId}) => ProductFormController(
        repository,
        vsync: const TestVSync(),
        branchId: branchId,
      );

  test('النموذج بيحمّل الأقسام الحقيقية ويختار أولها', () async {
    if (skip()) return;

    final ProductFormController form = newForm();
    await form.load();

    expect(form.hasFailed, isFalse, reason: form.errorMessage ?? '');
    expect(form.categories, isNotEmpty);
    expect(form.categoryId, form.categories.first.id);

    form.dispose();
  });

  test('مينفعش يتحفظ من غير اسم أو كود', () async {
    if (skip()) return;

    final ProductFormController form = newForm();
    await form.load();

    expect(form.canSave, isFalse, reason: 'فاضي تمامًا');

    form.nameController.text = 'منتج من غير كود';
    form.fieldChanged();
    expect(form.canSave, isFalse, reason: 'لسه مفيش SKU');

    form.skuController.text = uniqueSku();
    form.fieldChanged();
    expect(form.canSave, isTrue);

    form.dispose();
  });

  test('التكلفة الأعلى من السعر بتقفل الحفظ', () async {
    if (skip()) return;

    final ProductFormController form = newForm();
    await form.load();

    form.nameController.text = 'منتج خسران';
    form.skuController.text = uniqueSku();
    form.costController.text = '80';
    form.priceController.text = '50';
    form.fieldChanged();

    expect(form.isLoss, isTrue);
    expect(form.canSave, isFalse, reason: 'السيرفر بيرفض هامش سالب');

    form.dispose();
  });

  test('السعر بالكرتونة وعدد القطع في الكرتونة بيُحفظ في المنتج', () async {
    if (skip()) return;

    final ProductFormController form = newForm();
    await form.load();

    form.nameController.text = 'منتج كرتونة';
    form.skuController.text = uniqueSku();
    form.costController.text = '20';
    form.priceController.text = '30';
    form.cartonPriceController.text = '250';
    form.piecesPerCartonController.text = '12';
    form.fieldChanged();

    expect(form.cartonPrice, 250);
    expect(form.piecesPerCarton, 12);
    expect(form.canSave, isTrue);

    form.dispose();
  });

  test('حفظ منتج كامل بيرجّعه من السيرفر', () async {
    if (skip()) return;

    final ProductFormController form = newForm();
    await form.load();

    final String sku = uniqueSku();
    form.nameController.text = 'منتج اختبار آلي';
    form.skuController.text = sku;
    form.brandController.text = 'ماركة الاختبار';
    form.descriptionController.text = 'وصف بيتحفظ على السيرفر';
    form.costController.text = '30';
    form.priceController.text = '45.5';
    form.reorderController.text = '8';
    form.setUnit('علبة');

    final Product? saved = await form.save();

    expect(saved, isNotNull, reason: form.saveError ?? '');
    expect(saved!.sku, sku.toUpperCase(), reason: 'السيرفر بيكبّر الكود');
    expect(saved.name, 'منتج اختبار آلي');
    expect(saved.price, 45.5);
    expect(saved.cost, 30);
    expect(saved.unit, 'علبة');
    expect(saved.minStock, 8);
    expect(saved.categoryId, form.categoryId);

    form.dispose();
  });

  test('الرصيد الافتتاحي بيتسجّل في فرع المستخدم', () async {
    if (skip()) return;

    final List<Category> categories = await repository.fetchCategories();
    expect(categories, isNotEmpty);

    // بنجيب فرع من أي منتج موجود عن طريق قايمة الفروع في التقارير.
    final ApiResponse branches = await api.get(
      '/branches',
      query: <String, dynamic>{'limit': 1},
    );
    final String branchId = branches.list.first['id'] as String;

    final ProductFormController form = newForm(branchId: branchId);
    await form.load();

    form.nameController.text = 'منتج برصيد افتتاحي';
    form.skuController.text = uniqueSku();
    form.costController.text = '10';
    form.priceController.text = '20';
    form.openingStockController.text = '12';

    final Product? saved = await form.save();
    expect(saved, isNotNull, reason: form.saveError ?? '');

    // الرد الأول مفيهوش رصيد، فبنعيد القراءة بالفرع.
    final ApiResponse fresh = await api.get(
      '/products/${saved!.id}',
      query: <String, dynamic>{'branch': branchId},
    );

    expect(Product.fromJson(fresh.object).stock, 12);

    form.dispose();
  });

  test('كود مكرر بيرجّع رسالة السيرفر مش انهيار', () async {
    if (skip()) return;

    final String sku = uniqueSku();

    final ProductFormController first = newForm();
    await first.load();
    first.nameController.text = 'الأصلي';
    first.skuController.text = sku;
    first.costController.text = '5';
    first.priceController.text = '9';
    expect(await first.save(), isNotNull, reason: first.saveError ?? '');
    first.dispose();

    final ProductFormController second = newForm();
    await second.load();
    second.nameController.text = 'المكرر';
    second.skuController.text = sku;
    second.costController.text = '5';
    second.priceController.text = '9';

    expect(await second.save(), isNull);
    expect(second.saveError, isNotNull);
    expect(second.saveError, contains('مستخدم'));

    second.dispose();
  });

  test('المتغيرات الفاضية مبتتبعتش والمليانة بتتخزّن', () async {
    if (skip()) return;

    final ProductFormController form = newForm();
    await form.load();

    form.nameController.text = 'منتج بمتغيرات';
    form.skuController.text = uniqueSku();
    form.costController.text = '20';
    form.priceController.text = '35';

    // الصف الأول بيفضل فاضي، والتاني بيتملى.
    form.addVariant();
    final ProductVariant filled = form.variants.last;
    filled.size = 'L';
    filled.color = 'أزرق';
    filled.price = '40';

    expect(form.variants.first.isEmpty, isTrue);

    final Product? saved = await form.save();
    expect(saved, isNotNull, reason: form.saveError ?? '');

    final ApiResponse fresh = await api.get('/products/${saved!.id}');
    final List<dynamic> variants =
        fresh.object['variants'] as List<dynamic>? ?? <dynamic>[];

    expect(variants, hasLength(1), reason: 'الصف الفاضي اتشال');
    expect((variants.first as Map<String, dynamic>)['size'], 'L');
    expect((variants.first as Map<String, dynamic>)['priceOverride'], 40);

    form.dispose();
  });

  test('الباركود المولّد بيتحفظ مع المنتج', () async {
    if (skip()) return;

    final ProductFormController form = newForm();
    await form.load();

    form.generateBarcode();
    expect(form.barcode, hasLength(13));

    form.nameController.text = 'منتج بباركود';
    form.skuController.text = uniqueSku();
    form.costController.text = '12';
    form.priceController.text = '18';

    final Product? saved = await form.save();
    expect(saved, isNotNull, reason: form.saveError ?? '');
    expect(saved!.barcode, form.barcode);

    form.dispose();
  });
}
