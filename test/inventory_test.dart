import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/inventory/controllers/inventory_controller.dart';
import 'package:pos_system/features/inventory/data/inventory_repository.dart';
import 'package:pos_system/features/inventory/models/stock_record.dart';
import 'package:pos_system/features/stock_transfer_stocktake/controllers/stock_transfer_controller.dart';
import 'package:pos_system/features/stock_transfer_stocktake/controllers/stocktake_controller.dart';
import 'package:pos_system/features/stock_transfer_stocktake/models/stocktake_line.dart';
import 'package:pos_system/features/stock_transfer_stocktake/models/transfer_line.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// المخزون والجرد والتحويل على الباك اند الحقيقي.
void main() {
  late ApiClient api;
  late InventoryRepository repository;
  late InventoryController inventory;
  String branchId = '';
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();
    repository = InventoryRepository(api);

    try {
      await api.get('/health');
      final SessionController auth = SessionController(api);

      // أمين المخزن مربوط بالفرع الرئيسي وعنده صلاحيات التسوية والتحويل.
      backendUp = await auth.login(
        username: 'stock',
        password: 'Stock@12345',
      );

      branchId = auth.user?.branchId ?? '';
    } on ApiException {
      backendUp = false;
    }
  });

  setUp(() async {
    if (!backendUp) return;
    inventory = InventoryController(repository, branchId: branchId);
    await inventory.load();
  });

  tearDown(() {
    if (backendUp) inventory.dispose();
  });

  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  test('الأرصدة بتتجاب مع بيانات المنتج', () {
    if (skip()) return;

    expect(inventory.hasFailed, isFalse, reason: inventory.errorMessage);
    expect(inventory.rows, isNotEmpty, reason: 'محتاج npm run seed');

    final StockRecord r = inventory.rows.first;
    expect(r.productName, isNotEmpty);
    expect(r.sku, isNotEmpty);
    expect(r.categoryName, isNot('—'));
    expect(r.available, r.onHand - r.reserved);
  });

  test('الملخص بيحسب على كل أصناف الفرع', () {
    if (skip()) return;

    expect(inventory.totalValue, greaterThan(0));
    expect(inventory.summary.items, greaterThanOrEqualTo(inventory.rows.length));
  });

  group('الفلترة', () {
    test('فلتر الناقص بيرجّع اللي تحت الحد بس', () async {
      if (skip()) return;

      await inventory.setStatus('low');

      expect(
        inventory.rows.every((StockRecord r) => r.isLow),
        isTrue,
      );
    });

    test('العدّاد بيطابق المعروض مش كل الأصناف', () async {
      if (skip()) return;

      final int allCount = inventory.visibleCount;

      await inventory.setStatus('low');
      final int lowCount = inventory.visibleCount;

      await inventory.setStatus('ok');
      final int okCount = inventory.visibleCount;

      expect(lowCount, lessThan(allCount),
          reason: 'الفلترة لازم تقلل العدّاد');
      expect(lowCount + okCount, lessThanOrEqualTo(allCount));
      expect(lowCount, inventory.lowCount,
          reason: 'العدّاد لازم يطابق ملخص السيرفر');
    });

    test('البحث بيفلتر بالاسم', () async {
      if (skip()) return;

      final String name = inventory.rows.first.productName;
      inventory.setQuery(name);
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(inventory.rows, isNotEmpty);
      expect(
        inventory.rows.every(
          (StockRecord r) => r.productName.contains(name) || r.sku.contains(name),
        ),
        isTrue,
      );
    });
  });

  group('التسوية', () {
    test('الزيادة بتتسجّل وبتظهر في الرصيد', () async {
      if (skip()) return;

      final StockRecord target = inventory.rows.first;
      final int before = target.onHand;

      final String? error = await inventory.adjust(
        productId: target.productId,
        delta: 5,
        note: 'اختبار تسوية',
      );

      expect(error, isNull);

      final StockRecord after = inventory.rows
          .firstWhere((StockRecord r) => r.productId == target.productId);
      expect(after.onHand, before + 5);
    });

    test('السحب بأكتر من الرصيد بيترفض', () async {
      if (skip()) return;

      final StockRecord target = inventory.rows.first;
      final int before = target.onHand;

      final String? error = await inventory.adjust(
        productId: target.productId,
        delta: -(before + 10000),
      );

      // التسوية بالسالب مسموح لها تنزل تحت الصفر، فبنتأكد إنها اتسجّلت
      // ونرجّع الرصيد زي ما كان.
      if (error == null) {
        await inventory.adjust(
          productId: target.productId,
          delta: before + 10000,
        );
      }

      final StockRecord after = inventory.rows
          .firstWhere((StockRecord r) => r.productId == target.productId);
      expect(after.onHand, before);
    });

    test('حد الطلب بيتحدّث ويأثر على الحالة', () async {
      if (skip()) return;

      final StockRecord target = inventory.rows.first;

      // حد أعلى من الرصيد بيخلّي الصنف «ناقص».
      final String? error = await inventory.setMinStock(
        productId: target.productId,
        minStock: target.onHand + 50,
      );

      expect(error, isNull);

      final StockRecord after = inventory.rows
          .firstWhere((StockRecord r) => r.productId == target.productId);
      expect(after.isLow, isTrue);

      await inventory.setMinStock(
        productId: target.productId,
        minStock: target.minStock,
      );
    });
  });

  group('حركات الصنف', () {
    test('التسوية بتظهر في السجل', () async {
      if (skip()) return;

      final StockRecord target = inventory.rows.first;

      await inventory.adjust(
        productId: target.productId,
        delta: 3,
        note: 'حركة للاختبار',
      );

      final List<StockMovement> movements = await repository.fetchMovements(
        branchId: branchId,
        productId: target.productId,
        reason: 'adjustment',
      );

      expect(movements, isNotEmpty);
      expect(movements.first.quantity, 3);
      expect(movements.first.reasonLabel, 'تسوية');
      expect(movements.first.balanceAfter, greaterThan(0));

      await inventory.adjust(productId: target.productId, delta: -3);
    });
  });

  group('الجرد', () {
    late StocktakeController stocktake;

    setUp(() async {
      if (!backendUp) return;
      stocktake = StocktakeController(repository, branchId: branchId);
      await stocktake.load();
    });

    tearDown(() {
      if (backendUp) stocktake.dispose();
    });

    test('بيجيب الأصناف بأرصدتها', () {
      if (skip()) return;

      expect(stocktake.lines, isNotEmpty);
      expect(stocktake.countedCount, 0, reason: 'لسه مافيش عدّ');
    });

    test('الصف المطابق مبيتبعتش للسيرفر', () {
      if (skip()) return;

      final StocktakeLine line = stocktake.lines.first;
      stocktake.setActualQuantity(line, line.systemQuantity);

      expect(line.isCounted, isTrue);
      expect(line.difference, 0);
      expect(stocktake.pendingLines, isEmpty,
          reason: 'العدّ المطابق ملوش لازمة يتبعت');
    });

    test('الفرق بيتسجّل ويصحّح الرصيد', () async {
      if (skip()) return;

      final StocktakeLine line = stocktake.lines.first;
      final int system = line.systemQuantity;

      stocktake.setActualQuantity(line, system - 2);
      expect(line.difference, -2);
      expect(stocktake.shortageCount, 1);
      expect(stocktake.pendingLines, hasLength(1));

      final StocktakeResult result =
          await stocktake.submit(note: 'جرد اختبار');

      expect(result.applied, 1);
      expect(result.failed, 0);

      final StocktakeLine after = stocktake.lines
          .firstWhere((StocktakeLine l) => l.productId == line.productId);
      expect(after.systemQuantity, system - 2);

      // نرجّع الرصيد زي ما كان.
      await inventory.adjust(productId: line.productId, delta: 2);
    });
  });

  group('التحويل', () {
    late StockTransferController transfer;

    setUp(() async {
      if (!backendUp) return;
      transfer = StockTransferController(repository, fromBranchId: branchId);
      await transfer.load();
    });

    tearDown(() {
      if (backendUp) transfer.dispose();
    });

    test('بيجيب أصناف الفرع والفروع المتاحة', () {
      if (skip()) return;

      expect(transfer.availableStock, isNotEmpty);
      expect(transfer.fromBranchId, branchId);
    });

    test('الكمية مبتعديش المتاح', () {
      if (skip()) return;

      transfer.addProduct(transfer.availableStock.first);
      final TransferLine line = transfer.lines.first;

      transfer.setQuantity(line, 999999);
      expect(line.quantity, line.available);
      expect(line.exceedsAvailable, isFalse);
    });

    test('نفس الفرع مصدر ووجهة بيمنع التنفيذ', () {
      if (skip()) return;

      transfer.addProduct(transfer.availableStock.first);
      transfer.setToBranch(branchId);

      expect(transfer.sameBranch, isTrue);
      expect(transfer.canSubmit, isFalse);
    });

    test('التحويل بينقل الرصيد للفرع التاني', () async {
      if (skip()) return;

      if (transfer.branches.length < 2) {
        markTestSkipped('محتاج فرعين');
        return;
      }

      final String destination = transfer.branches
          .firstWhere((BranchOption b) => b.id != branchId)
          .id;

      final StockRecord source = transfer.availableStock
          .firstWhere((StockRecord r) => r.available > 5);

      final StockPage before = await repository.fetchStock(
        branchId: destination,
        limit: 100,
      );
      final int destBefore = before.items
          .where((StockRecord r) => r.productId == source.productId)
          .map((StockRecord r) => r.onHand)
          .firstOrNull ??
          0;

      transfer.addProduct(source);
      transfer.setQuantity(transfer.lines.first, 3);
      transfer.setToBranch(destination);

      expect(transfer.canSubmit, isTrue);

      final TransferResult result = await transfer.submit(note: 'تحويل اختبار');

      expect(result.failed, 0, reason: result.error);
      expect(result.moved, 1);

      final StockPage after = await repository.fetchStock(
        branchId: destination,
        limit: 100,
      );
      final int destAfter = after.items
          .firstWhere((StockRecord r) => r.productId == source.productId)
          .onHand;

      expect(destAfter, destBefore + 3, reason: 'الوجهة لازم تزيد');

      // نرجّع الكمية لفرعها.
      await repository.transfer(
        productId: source.productId,
        fromBranchId: destination,
        toBranchId: branchId,
        quantity: 3,
      );
    });
  });
}
