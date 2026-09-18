import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/data/branches_repository.dart';
import 'package:pos_system/core/models/branch.dart';
import 'package:pos_system/core/models/category.dart';
import 'package:pos_system/core/models/product.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/cashier_shift/data/shift_repository.dart';
import 'package:pos_system/features/categories/data/categories_repository.dart';
import 'package:pos_system/features/inventory/data/inventory_repository.dart';
import 'package:pos_system/features/inventory/data/stock_alerts_repository.dart';
import 'package:pos_system/features/pos_sale/controllers/sales_session_controller.dart';
import 'package:pos_system/features/pos_sale/data/pos_repository.dart';
import 'package:pos_system/features/product_profile/controllers/product_profile_controller.dart';
import 'package:pos_system/features/products_list/data/products_repository.dart';
import 'package:pos_system/features/returns/data/returns_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// الأقسام وتعديل أسعار المنتجات والتنبيهات وسجل المرتجعات ووردية مدير النظام
/// على الباك اند الحقيقي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // الـbinding بيحجب الشبكة، والاختبار ده بيضرب السيرفر فعلًا.
  HttpOverrides.global = null;

  late ApiClient api;
  bool backendUp = false;

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

  test('إضافة قسم وتعديله وحذفه', () async {
    if (skip()) return;

    final CategoriesRepository categories = CategoriesRepository(api);
    final String name = 'قسم اختبار ${unique()}';

    final Category created = await categories.create(
      CategoryInput(name: name, iconName: 'spa', colorHex: '#10B981'),
    );
    expect(created.iconName, 'spa');

    final Category updated = await categories.update(
      created.id,
      CategoryInput(name: '$name معدّل', iconName: 'pets', colorHex: '#EF4444'),
    );
    expect(updated.name, '$name معدّل');

    final List<Category> all = await categories.fetchAll();
    expect(all.any((Category c) => c.id == created.id), isTrue);

    // القسم فاضي فبيتمسح فعلًا مش بيتعطّل.
    final CategoryRemoval removal = await categories.remove(created.id);
    expect(removal.deleted, isTrue);
  });

  test('تعديل سعر منتج من تفاصيله بيتحفظ على السيرفر', () async {
    if (skip()) return;

    final ProductsRepository products = ProductsRepository(api);
    final List<Category> categories = await products.fetchCategories();

    final Product product = await products.create(
      name: 'منتج أسعار ${unique()}',
      sku: 'PRC-${unique()}',
      categoryId: categories.first.id,
      price: 100,
      cost: 50,
    );

    try {
      final ProductProfileController profile = ProductProfileController(
        products,
        InventoryRepository(api),
        productId: product.id,
        vsync: const TestVSync(),
      );

      await profile.load();
      expect(profile.hasFailed, isFalse, reason: profile.errorMessage);
      expect(profile.product!.price, 100);
      expect(profile.isDirty, isFalse);

      profile.priceController.text = '135.5';
      profile.fieldChanged();
      expect(profile.isDirty, isTrue);
      expect(profile.problem, isNull);

      expect(await profile.save(), isNull);
      expect(profile.isDirty, isFalse);

      // بنقرا من السيرفر من جديد عشان نتأكد إن السعر اتخزن مش في الذاكرة بس.
      expect((await products.fetchForEdit(product.id)).product.price, 135.5);

      // السيرفر بيرفض السعر الأقل من التكلفة، والشاشة بتمسكها قبل ما تبعت.
      profile.priceController.text = '10';
      profile.fieldChanged();
      expect(profile.problem, 'التكلفة أعلى من سعر البيع');
      expect(profile.canSave, isFalse);

      profile.discardChanges();
      expect(profile.priceController.text, '135.5');

      // الباركود بيتحط وبيتشال من نفس الشاشة.
      profile.barcodeController.text = '6221031234567';
      profile.fieldChanged();
      expect(await profile.save(), isNull);
      expect(
        (await products.fetchForEdit(product.id)).product.barcode,
        '6221031234567',
      );

      profile.barcodeController.text = '';
      profile.fieldChanged();
      expect(await profile.save(), isNull);
      expect((await products.fetchForEdit(product.id)).product.barcode, isNull);

      // الإيقاف والتفعيل من نفس الشاشة.
      expect(await profile.toggleActive(), isNull);
      expect(profile.product!.isActive, isFalse);
      expect(await profile.toggleActive(), isNull);
      expect(profile.product!.isActive, isTrue);

      profile.dispose();
    } finally {
      await products.setActiveState(product.id, isActive: false);
    }
  });

  test('تنبيهات المخزون وسجل المرتجعات بيرجعوا من غير أخطاء', () async {
    if (skip()) return;

    final StockAlertsRepository alerts = StockAlertsRepository(api);
    final List<LowStockAlert> low = await alerts.fetchLowStock();
    for (final LowStockAlert a in low) {
      expect(a.quantity, lessThanOrEqualTo(a.minStock));
    }

    final List<ExpiringProduct> expiring = await alerts.fetchExpiring(days: 90);
    for (final ExpiringProduct p in expiring) {
      expect(p.daysLeft, lessThanOrEqualTo(90));
    }

    final ReturnsHistoryRepository returns = ReturnsHistoryRepository(api);
    final ReturnsPage page = await returns.fetchPage();
    final ReturnsSummary summary = await returns.fetchSummary();
    expect(summary.count, page.total);

    if (page.items.isNotEmpty) {
      final String id = page.items.first.id;
      expect((await returns.fetchOne(id)).lines, isNotEmpty);
    }
  });

  test('مدير النظام من غير فرع بيفتح وردية في فرع ويبيع فيه', () async {
    if (skip()) return;

    final ShiftRepository shifts = ShiftRepository(api);
    final Branch branch = (await BranchesRepository(api).fetchAll()).first;

    // وردية فاضلة من تشغيل قبل كده بتتقفل الأول.
    final ShiftSnapshot? existing = await shifts.fetchCurrent();
    if (existing != null) {
      await shifts.close(existing.shift.id, countedCash: 0);
    }

    final ShiftSnapshot opened = await shifts.open(
      openingBalance: 100,
      branchId: branch.id,
    );
    expect(opened.shift.branchId, branch.id);

    try {
      final SalesSessionController session = SalesSessionController(
        PosRepository(api),
        branchId: branch.id,
      );
      await session.load();

      final Product target = session.products.firstWhere(
        (Product p) => p.trackStock && p.stock > 5,
      );
      session.active.addProduct(target);

      // الفاتورة مش بتبعت فرع — السيرفر بياخده من الوردية المفتوحة.
      final CompletedInvoice invoice = await session.checkout(<PaymentInput>[
        PaymentInput(method: 'cash', amount: session.active.total),
      ]);
      expect(invoice.number, isNotEmpty);

      final ApiResponse saved = await api.get('/invoices/${invoice.id}');
      final dynamic invoiceBranch = saved.object['branch'];
      expect(
        invoiceBranch is Map<String, dynamic>
            ? invoiceBranch['id']
            : invoiceBranch,
        branch.id,
      );

      session.dispose();
    } finally {
      await shifts.close(opened.shift.id, countedCash: 100);
    }
  });
}
