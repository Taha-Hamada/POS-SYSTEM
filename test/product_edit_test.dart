import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/models/category.dart';
import 'package:pos_system/core/models/product.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/add_edit_product/controllers/product_form_controller.dart';
import 'package:pos_system/features/products_list/data/products_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Vsync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

/// تعديل منتج موجود على الباك اند الحقيقي.
void main() {
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
      backendUp = await SessionController(
        api,
      ).login(username: 'admin', password: 'Admin@12345');
    } on ApiException {
      backendUp = false;
    }
  });

  tearDownAll(() => api.dispose());

  test('الفورم بيتملى بالمنتج وبيحفظ التعديل من غير ما يلمس الرصيد', () async {
    if (!backendUp) {
      markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
      return;
    }

    final List<Category> categories = await repository.fetchCategories();
    final String sku = 'EDIT-${DateTime.now().millisecondsSinceEpoch}';

    final Product created = await repository.create(
      name: 'منتج قبل التعديل',
      sku: sku,
      categoryId: categories.first.id,
      price: 20,
      cost: 12,
      description: 'وصف قديم',
      variants: const <ProductVariantInput>[
        ProductVariantInput(size: 'كبير', priceOverride: 25),
      ],
    );

    final ProductFormController form = ProductFormController(
      repository,
      vsync: _Vsync(),
      productId: created.id,
    );
    await form.load();

    expect(form.isEditing, isTrue);
    expect(form.nameController.text, 'منتج قبل التعديل');
    expect(form.descriptionController.text, 'وصف قديم');
    expect(form.priceController.text, '20');
    expect(form.variants.first.size, 'كبير');
    expect(form.variants.first.price, '25');

    form.nameController.text = 'منتج بعد التعديل';
    form.priceController.text = '22.5';

    final Product? saved = await form.save();
    expect(form.saveError, isNull);
    expect(saved?.name, 'منتج بعد التعديل');
    expect(saved?.price, 22.5);

    final ProductDraft reloaded = await repository.fetchForEdit(created.id);
    expect(reloaded.product.sku, sku.toUpperCase());
    expect(reloaded.variants, hasLength(1));

    await repository.setActiveState(created.id, isActive: false);
    form.dispose();
  });
}
