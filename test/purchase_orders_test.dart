import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/data/branches_repository.dart';
import 'package:pos_system/core/models/branch.dart';
import 'package:pos_system/core/models/product.dart';
import 'package:pos_system/core/models/purchase_order.dart';
import 'package:pos_system/core/models/supplier.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/products_list/data/products_repository.dart';
import 'package:pos_system/features/purchase_orders/controllers/create_purchase_order_controller.dart';
import 'package:pos_system/features/purchase_orders/controllers/purchase_orders_controller.dart';
import 'package:pos_system/features/purchase_orders/controllers/receive_goods_controller.dart';
import 'package:pos_system/features/purchase_orders/data/purchases_repository.dart';
import 'package:pos_system/features/purchase_orders/models/purchase_orders_sort_column.dart';
import 'package:pos_system/features/suppliers/data/suppliers_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// أوامر الشراء وهي بتقرا وتكتب على الباك اند الحقيقي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // الـbinding بيحجب الشبكة، والاختبار ده بيضرب السيرفر فعلًا.
  HttpOverrides.global = null;

  late ApiClient api;
  late PurchasesRepository repository;
  late SuppliersRepository suppliersRepository;
  late ProductsRepository productsRepository;
  late BranchesRepository branchesRepository;
  late PurchaseOrdersController orders;

  late String supplierId;
  late String branchId;
  late List<Product> catalog;

  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();
    repository = PurchasesRepository(api);
    suppliersRepository = SuppliersRepository(api);
    productsRepository = ProductsRepository(api);
    branchesRepository = BranchesRepository(api);

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

    if (!backendUp) return;

    final SuppliersPage suppliers =
        await suppliersRepository.fetchPage(isActive: true, limit: 1);
    final List<Branch> branches = await branchesRepository.fetchAll();
    catalog = await productsRepository.fetchAll();

    supplierId = suppliers.items.first.id;
    branchId = branches.first.id;
  });

  setUp(() async {
    if (!backendUp) return;
    orders = PurchaseOrdersController(repository, suppliersRepository);
    await orders.load();
  });

  tearDown(() {
    if (backendUp) orders.dispose();
  });

  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  /// أمر مسودة بصنفين — نقطة البداية لأغلب الاختبارات.
  Future<PurchaseOrder> newOrder({double shippingCost = 0}) => repository.create(
        supplierId: supplierId,
        branchId: branchId,
        shippingCost: shippingCost,
        note: 'أمر من الاختبارات',
        lines: <PurchaseLineInput>[
          (productId: catalog[0].id, quantity: 10, unitCost: 12),
          (productId: catalog[1].id, quantity: 5, unitCost: 20),
        ],
      );

  test('إنشاء أمر بيحسب الإجمالي بالشحن من غير ضريبة', () async {
    if (skip()) return;

    final PurchaseOrder order = await newOrder(shippingCost: 50);

    expect(order.number, startsWith('PO-'));
    expect(order.status, PurchaseOrderStatus.draft);
    expect(order.subtotal, 10 * 12 + 5 * 20);
    expect(order.shippingCost, 50);
    expect(order.total, order.subtotal + 50, reason: 'مفيش ضريبة على الأمر');
    expect(order.totalQuantity, 15);
    expect(order.receivedQuantity, 0);
    expect(order.lines, hasLength(2));
    expect(order.lines.first.id, isNotEmpty, reason: 'الاستلام محتاج معرّف السطر');
  });

  test('الملخّص بيعدّ كل الأوامر مش الصفحة', () async {
    if (skip()) return;

    await newOrder();
    await orders.load();

    final PurchaseOrdersSummary summary = await repository.fetchSummary();
    final int draftCount = summary.byStatus[PurchaseOrderStatus.draft]!.count;

    expect(orders.countByStatus(PurchaseOrderStatus.draft), draftCount);
    expect(draftCount, greaterThan(0));
    expect(
      orders.awaitingCount,
      summary.byStatus[PurchaseOrderStatus.confirmed]!.count +
          summary.byStatus[PurchaseOrderStatus.partiallyReceived]!.count,
    );
  });

  test('القايمة بترجع من غير سطور والأمر المفرد بيرجّعها', () async {
    if (skip()) return;

    final PurchaseOrder created = await newOrder();
    final PurchaseOrdersPage page = await repository.fetchPage(search: created.number);

    expect(page.items, hasLength(1));
    expect(page.items.single.supplierName, isNotEmpty);
    expect(page.items.single.totalQuantity, 15, reason: 'الإجمالي جاي كـvirtual');

    // القايمة بتشيل السطور وتسيب إجمالياتها.
    expect(page.items.single.lines, isEmpty);
    expect(page.items.single.receivedRatio, 0);

    final PurchaseOrder full = await repository.fetchOne(created.id);
    expect(full.lines, hasLength(2));
  });

  test('تعديل المسودة بيعيد حساب الإجمالي', () async {
    if (skip()) return;

    final PurchaseOrder created = await newOrder();

    final PurchaseOrder updated = await repository.update(
      created.id,
      shippingCost: 75,
      lines: <PurchaseLineInput>[
        (productId: catalog[0].id, quantity: 3, unitCost: 12),
      ],
    );

    expect(updated.subtotal, 36);
    expect(updated.total, 111);
    expect(updated.lines, hasLength(1));
  });

  test('المؤكد مبيتعدلش', () async {
    if (skip()) return;

    final PurchaseOrder created = await newOrder();
    await repository.confirm(created.id);

    await expectLater(
      repository.update(created.id, shippingCost: 10),
      throwsA(isA<ApiException>()),
    );
  });

  test('المسودة مينفعش تتستلم قبل التأكيد', () async {
    if (skip()) return;

    final PurchaseOrder created = await newOrder();

    await expectLater(
      repository.receive(
        created.id,
        lines: <ReceiptLineInput>[
          (orderLineId: created.lines.first.id, quantity: 1, unitCost: null),
        ],
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('الاستلام الجزئي بيحرّك المخزون ويحمّل حساب المورد', () async {
    if (skip()) return;

    final PurchaseOrder created = await newOrder();
    await repository.confirm(created.id);

    final Supplier before = await suppliersRepository.fetchOne(supplierId);
    final ApiResponse stockBefore = await api.get(
      '/products/${catalog[0].id}',
      query: <String, dynamic>{'branch': branchId},
    );
    final int quantityBefore = Product.fromJson(stockBefore.object).stock;

    final PurchaseOrder received = await repository.receive(
      created.id,
      updateCost: false,
      lines: <ReceiptLineInput>[
        (orderLineId: created.lines.first.id, quantity: 4, unitCost: 12),
      ],
    );

    expect(received.status, PurchaseOrderStatus.partiallyReceived);
    expect(received.receivedValue, 48);
    expect(received.receivedQuantity, 4);

    final ApiResponse stockAfter = await api.get(
      '/products/${catalog[0].id}',
      query: <String, dynamic>{'branch': branchId},
    );
    expect(Product.fromJson(stockAfter.object).stock, quantityBefore + 4);

    final Supplier after = await suppliersRepository.fetchOne(supplierId);
    expect(after.balanceDue, closeTo(before.balanceDue + 48, 0.01));
  });

  test('استلام أكتر من المطلوب بيترفض', () async {
    if (skip()) return;

    final PurchaseOrder created = await newOrder();
    await repository.confirm(created.id);

    await expectLater(
      repository.receive(
        created.id,
        lines: <ReceiptLineInput>[
          (orderLineId: created.lines.first.id, quantity: 999, unitCost: null),
        ],
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('استلام كل الأصناف بيقفل الأمر ويعدّ للمورد', () async {
    if (skip()) return;

    final PurchaseOrder created = await newOrder();
    await repository.confirm(created.id);

    final Supplier before = await suppliersRepository.fetchOne(supplierId);

    final PurchaseOrder received = await repository.receive(
      created.id,
      updateCost: false,
      lines: <ReceiptLineInput>[
        for (final PurchaseOrderLine l in created.lines)
          (orderLineId: l.id, quantity: l.quantity, unitCost: null),
      ],
    );

    expect(received.status, PurchaseOrderStatus.completed);
    expect(received.receivedQuantity, received.totalQuantity);
    expect(received.receivedRatio, 1);

    final Supplier after = await suppliersRepository.fetchOne(supplierId);
    expect(after.ordersCount, before.ordersCount + 1);
    expect(after.totalPurchases, greaterThan(before.totalPurchases));
  });

  test('الإلغاء لازم له سبب، والمستلم جزئيًا مبيتلغيش', () async {
    if (skip()) return;

    final PurchaseOrder created = await newOrder();

    final PurchaseOrder cancelled =
        await repository.cancel(created.id, reason: 'المورد اعتذر');
    expect(cancelled.status, PurchaseOrderStatus.cancelled);
    expect(cancelled.canCancel, isFalse);

    final PurchaseOrder other = await newOrder();
    await repository.confirm(other.id);
    await repository.receive(
      other.id,
      updateCost: false,
      lines: <ReceiptLineInput>[
        (orderLineId: other.lines.first.id, quantity: 1, unitCost: null),
      ],
    );

    await expectLater(
      repository.cancel(other.id, reason: 'اتأخر'),
      throwsA(isA<ApiException>()),
    );
  });

  test('فلتر الحالة بيرجّع المسودات بس', () async {
    if (skip()) return;

    await newOrder();
    await orders.setStatus(PurchaseOrderStatus.draft);

    expect(orders.rows, isNotEmpty);
    expect(orders.rows.every((PurchaseOrder o) => o.isDraft), isTrue);
    expect(orders.visibleCount, orders.countByStatus(PurchaseOrderStatus.draft));
  });

  test('فلتر المورد بيقلّل الصفوف والملخّص', () async {
    if (skip()) return;

    await newOrder();
    // العدّاد اتقرا قبل الأمر الجديد، فبنعيد التحميل الأول.
    await orders.load();
    final int all = orders.visibleCount;

    await orders.setSupplier(supplierId);

    expect(orders.visibleCount, lessThanOrEqualTo(all));
    expect(
      orders.rows.every((PurchaseOrder o) => o.supplierId == supplierId),
      isTrue,
    );
  });

  test('الفرز بالإجمالي بيتنفّذ على السيرفر', () async {
    if (skip()) return;

    await orders.sortBy(PurchaseOrdersSortColumn.total.index, false);

    final List<PurchaseOrder> rows = orders.rows;
    for (int i = 1; i < rows.length; i += 1) {
      expect(rows[i - 1].total, greaterThanOrEqualTo(rows[i].total));
    }
  });

  test('نموذج الأمر الجديد بيحمّل الموردين والفروع والكتالوج', () async {
    if (skip()) return;

    final CreatePurchaseOrderController draft = CreatePurchaseOrderController(
      repository,
      suppliersRepository,
      productsRepository,
      branchesRepository,
      branchId: branchId,
    );

    await draft.load();

    expect(draft.hasFailed, isFalse, reason: draft.errorMessage ?? '');
    expect(draft.suppliers, isNotEmpty);
    expect(draft.branches, isNotEmpty);
    expect(draft.catalog, isNotEmpty);
    expect(draft.branchId, branchId);
    expect(draft.canSubmit, isFalse, reason: 'مفيش أصناف لسه');

    draft.addProduct(draft.catalog.first);
    draft.shippingController.text = '30';

    expect(draft.canSubmit, isTrue);
    expect(draft.total, draft.subtotal + 30);

    // نفس الصنف مبيتضافش مرتين.
    draft.addProduct(draft.catalog.first);
    expect(draft.lines, hasLength(1));

    draft.dispose();
  });

  test('النموذج بيبعت الأمر ويأكده في خطوة واحدة', () async {
    if (skip()) return;

    final CreatePurchaseOrderController draft = CreatePurchaseOrderController(
      repository,
      suppliersRepository,
      productsRepository,
      branchesRepository,
      branchId: branchId,
    );

    await draft.load();
    draft.setSupplier(supplierId);
    draft.addProduct(draft.catalog.first);
    draft.setQuantity(draft.lines.first, 7);
    draft.setUnitCost(draft.lines.first, 9.5);

    final PurchaseOrder? created = await draft.submit(confirm: true);

    expect(created, isNotNull, reason: draft.saveError ?? '');
    expect(created!.status, PurchaseOrderStatus.confirmed);
    expect(created.subtotal, closeTo(66.5, 0.01));
    expect(created.supplierId, supplierId);

    draft.dispose();
  });

  test('كتالوج المورد بيضيف اللي اتطلب منه قبل كده', () async {
    if (skip()) return;

    // أمر مكتمل عشان يبقى للمورد أصناف معروفة.
    final PurchaseOrder seed = await newOrder();
    await repository.confirm(seed.id);

    final CreatePurchaseOrderController draft = CreatePurchaseOrderController(
      repository,
      suppliersRepository,
      productsRepository,
      branchesRepository,
      branchId: branchId,
    );

    await draft.load();
    draft.setSupplier(supplierId);

    final ({int added, String? error}) result = await draft.addSupplierCatalog();

    expect(result.error, isNull);
    expect(result.added, greaterThan(0));
    expect(draft.lines, hasLength(result.added));

    draft.dispose();
  });

  test('حوار الاستلام بيبعت الصفوف اللي فيها كمية بس', () async {
    if (skip()) return;

    final PurchaseOrder created = await newOrder();
    await repository.confirm(created.id);

    final PurchaseOrder full = await repository.fetchOne(created.id);
    final ReceiveGoodsController receive =
        ReceiveGoodsController(repository, order: full);

    receive.clearAll();
    expect(receive.canSubmit, isFalse, reason: 'كله صفر');

    receive.setReceivingNow(receive.lines.first, 2);
    expect(receive.canSubmit, isTrue);
    expect(receive.receivingValue, 24);

    // مينفعش يستلم أكتر من المتبقي.
    receive.setReceivingNow(receive.lines.first, 500);
    expect(receive.lines.first.receivingNow, full.lines.first.quantity);

    receive.setReceivingNow(receive.lines.first, 2);
    receive.setUpdateCost(value: false);

    final PurchaseOrder? updated = await receive.submit();

    expect(updated, isNotNull, reason: receive.submitError ?? '');
    expect(updated!.status, PurchaseOrderStatus.partiallyReceived);
    expect(updated.receivedQuantity, 2, reason: 'الصف التاني مبعتش');

    receive.dispose();
  });

  test('الاستلام بالمتوسط المرجح بيحرّك تكلفة الصنف', () async {
    if (skip()) return;

    final Product product = catalog.firstWhere((Product p) => p.cost > 0);

    // سعر شراء أعلى من التكلفة الحالية عشان الأثر يبان.
    final double higherCost = product.cost * 2 + 5;

    final PurchaseOrder created = await repository.create(
      supplierId: supplierId,
      branchId: branchId,
      lines: <PurchaseLineInput>[
        (productId: product.id, quantity: 20, unitCost: higherCost),
      ],
    );

    await repository.confirm(created.id);
    await repository.receive(
      created.id,
      lines: <ReceiptLineInput>[
        (orderLineId: created.lines.first.id, quantity: 20, unitCost: higherCost),
      ],
    );

    final ApiResponse fresh = await api.get('/products/${product.id}');
    final double newCost = Product.fromJson(fresh.object).cost;

    expect(newCost, greaterThan(product.cost));
    expect(
      newCost,
      lessThanOrEqualTo(higherCost + 0.01),
      reason: 'المتوسط مينفعش يعدّي سعر الشحنة',
    );
  });
}
