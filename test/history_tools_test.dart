import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/data/branches_repository.dart';
import 'package:pos_system/core/models/branch.dart';
import 'package:pos_system/core/models/product.dart';
import 'package:pos_system/core/models/shift.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/cashier_shift/data/shift_repository.dart';
import 'package:pos_system/features/inventory/data/inventory_repository.dart';
import 'package:pos_system/features/invoices/data/invoices_repository.dart';
import 'package:pos_system/features/invoices/models/invoice_record.dart';
import 'package:pos_system/features/pos_sale/controllers/sales_session_controller.dart';
import 'package:pos_system/features/pos_sale/data/pos_repository.dart';
import 'package:pos_system/features/stock_transfer_stocktake/controllers/stocktake_controller.dart';
import 'package:pos_system/features/stock_transfer_stocktake/models/stocktake_line.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سجل الفواتير والإلغاء، سجل الورديات، الجرد، وتغيير كلمة السر
/// على الباك اند الحقيقي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // الـbinding بيحجب الشبكة، والاختبار ده بيضرب السيرفر فعلًا.
  HttpOverrides.global = null;

  late ApiClient api;
  late SessionController session;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();

    try {
      await api.get('/health');
      session = SessionController(api);
      backendUp = await session.login(
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

  test('فاتورة جديدة بتظهر في السجل بالبحث وبتتلغي مرة واحدة بس', () async {
    if (skip()) return;

    final ShiftRepository shifts = ShiftRepository(api);
    final Branch branch = (await BranchesRepository(api).fetchAll()).first;

    final ShiftSnapshot? existing = await shifts.fetchCurrent();
    if (existing != null) {
      await shifts.close(existing.shift.id, countedCash: 0);
    }

    final ShiftSnapshot opened = await shifts.open(
      openingBalance: 100,
      branchId: branch.id,
    );

    try {
      final SalesSessionController sales = SalesSessionController(
        PosRepository(api),
        branchId: branch.id,
      );
      await sales.load();

      final Product target = sales.products.firstWhere(
        (Product p) => p.trackStock && p.price > 0 && p.stock > 5,
      );
      sales.active
        ..addProduct(target)
        ..addProduct(target);

      final CompletedInvoice sold = await sales.checkout(<PaymentInput>[
        PaymentInput(method: 'cash', amount: sales.active.total),
      ]);
      sales.dispose();

      final InvoicesRepository invoices = InvoicesRepository(api);

      final InvoicesPage page = await invoices.fetchPage(search: sold.number);
      expect(
        page.items.map((InvoiceRecord i) => i.number),
        contains(sold.number),
      );

      final InvoiceRecord detail = await invoices.fetchOne(sold.id);
      expect(detail.lines, isNotEmpty);
      expect(detail.payments.first.method, 'cash');
      expect(detail.canVoid, isTrue);

      final InvoiceRecord voided = await invoices.voidInvoice(
        sold.id,
        reason: 'اختبار الإلغاء',
      );
      expect(voided.isVoided, isTrue);

      final InvoicesPage voidedPage = await invoices.fetchPage(
        status: 'voided',
        search: sold.number,
      );
      expect(voidedPage.items, isNotEmpty);

      await expectLater(
        invoices.voidInvoice(sold.id, reason: 'تاني'),
        throwsA(isA<ApiException>()),
      );

      // المخزون رجع بعد الإلغاء.
      final SalesSessionController after = SalesSessionController(
        PosRepository(api),
        branchId: branch.id,
      );
      await after.load();
      final Product restored = after.products.firstWhere(
        (Product p) => p.id == target.id,
      );
      expect(restored.stock, target.stock);
      after.dispose();
    } finally {
      await shifts.close(opened.shift.id, countedCash: 100);
    }

    final ({List<Shift> items, int total}) history = await shifts.fetchPage(
      status: 'closed',
    );
    final Shift closed = history.items.firstWhere(
      (Shift s) => s.id == opened.shift.id,
    );
    expect(closed.closing, isNotNull);
    expect(closed.closedAt, isNotNull);
  });

  test('اعتماد الجرد بيرحّل الفرق فعلًا', () async {
    if (skip()) return;

    final Branch branch = (await BranchesRepository(api).fetchAll()).first;
    final StocktakeController stocktake = StocktakeController(
      InventoryRepository(api),
      branchId: branch.id,
    );
    await stocktake.load();

    final StocktakeLine line = stocktake.lines.first;
    final String productId = line.productId;
    final double original = line.systemQuantity;

    stocktake.setActualQuantity(line, original + 1);
    final StocktakeResult result = await stocktake.submit(note: 'اختبار');
    expect(result, (applied: 1, failed: 0));

    StocktakeLine reloaded() => stocktake.lines.firstWhere(
      (StocktakeLine l) => l.productId == productId,
    );
    expect(reloaded().systemQuantity, original + 1);

    // رجوع للرصيد الأصلي.
    stocktake.setActualQuantity(reloaded(), original);
    await stocktake.submit(note: 'رجوع اختبار');
    expect(reloaded().systemQuantity, original);

    stocktake.dispose();
  });

  test('تغيير كلمة السر بكلمة حالية غلط بيرجّع رسالة ومبيخرجش', () async {
    if (skip()) return;

    final String? error = await session.changePassword(
      currentPassword: 'Wrong@00000',
      newPassword: 'Another@12345',
    );

    expect(error, 'كلمة السر الحالية غير صحيحة');
    expect(session.isAuthenticated, isTrue);
  });
}
