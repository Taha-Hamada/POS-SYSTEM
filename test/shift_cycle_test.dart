import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/models/product.dart';
import 'package:pos_system/core/models/shift.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/cashier_shift/controllers/current_shift_controller.dart';
import 'package:pos_system/features/cashier_shift/data/shift_repository.dart';
import 'package:pos_system/features/pos_sale/controllers/sales_session_controller.dart';
import 'package:pos_system/features/invoices/data/invoices_repository.dart';
import 'package:pos_system/features/pos_sale/data/pos_repository.dart';
import 'package:pos_system/features/returns/controllers/returns_controller.dart';
import 'package:pos_system/features/returns/data/returns_repository.dart';
import 'package:pos_system/features/returns/models/return_line.dart';
import 'package:pos_system/features/returns/models/returnable_invoice.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// دورة الوردية كاملة على الباك اند الحقيقي: فتح، بيع، حركات درج، تقفيل.
/// لو السيرفر مقفول الاختبارات بتتخطّى.
void main() {
  late ApiClient api;
  late CurrentShiftController shifts;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();

    try {
      await api.get('/health');
      final SessionController auth = SessionController(api);
      // حساب على الفرع الرئيسي لأنه اللي فيه مخزون،
      // ومنفصل عن حساب اختبارات البيع عشان الورديات ماتتلخبطش.
      backendUp = await auth.login(
        username: 'manager',
        password: 'Manager@123',
      );
    } on ApiException {
      backendUp = false;
    }
  });

  setUp(() async {
    if (!backendUp) return;

    shifts = CurrentShiftController(ShiftRepository(api));
    await shifts.load();

    // أي وردية فاضلة من اختبار قبله بتتقفل عشان نبدأ من حالة معروفة.
    if (shifts.isOpen) {
      await shifts.close(countedCash: shifts.totals.expectedCash);
    }
  });

  tearDown(() async {
    if (!backendUp) return;
    if (shifts.isOpen) {
      await shifts.close(countedCash: shifts.totals.expectedCash);
    }
    shifts.dispose();
  });

  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  test('مفيش وردية مفتوحة في الأول', () {
    if (skip()) return;

    expect(shifts.isOpen, isFalse);
    expect(shifts.shift, isNull);
  });

  test('فتح وردية بيرجّع رقمها ورصيدها', () async {
    if (skip()) return;

    final String? error = await shifts.open(1500);

    expect(error, isNull);
    expect(shifts.isOpen, isTrue);
    expect(shifts.shift!.number, startsWith('SH-'));
    expect(shifts.openingBalance, 1500);
    // الدرج بيبان فيه الرصيد الافتتاحي من أول لحظة، مش صفر.
    expect(shifts.totals.expectedCash, 1500);
  });

  test('وردية تانية مفتوحة بترفض برسالة واضحة', () async {
    if (skip()) return;

    await shifts.open(500);
    final String? error = await shifts.open(500);

    expect(error, isNotNull);
    expect(error, contains('وردية'));
  });

  test('التقفيل من غير وردية بيرجّع رسالة مش انهيار', () async {
    if (skip()) return;

    final String? error = await shifts.close(countedCash: 100);
    expect(error, 'مفيش وردية مفتوحة');
  });

  group('الدرج', () {
    test('الإيداع بيزوّد الكاش المتوقع', () async {
      if (skip()) return;

      await shifts.open(1000);

      final String? error = await shifts.addCash(
        isIn: true,
        amount: 200,
        reason: 'عهدة إضافية',
      );

      expect(error, isNull);
      expect(shifts.totals.cashIn, 200);
      expect(shifts.totals.expectedCash, 1200);
    });

    test('السحب بينقّص الكاش المتوقع', () async {
      if (skip()) return;

      await shifts.open(1000);
      await shifts.addCash(isIn: false, amount: 300, reason: 'توريد للخزنة');

      expect(shifts.totals.cashOut, 300);
      expect(shifts.totals.expectedCash, 700);
    });

    test('سحب أكتر من اللي في الدرج بيترفض', () async {
      if (skip()) return;

      await shifts.open(100);

      final String? error = await shifts.addCash(
        isIn: false,
        amount: 99999,
        reason: 'توريد',
      );

      expect(error, isNotNull);
      expect(shifts.totals.cashOut, 0, reason: 'الرفض ملازمش يغيّر الدرج');
    });
  });

  group('البيع داخل الوردية', () {
    test('الفاتورة بتظهر في أرقام الوردية', () async {
      if (skip()) return;

      await shifts.open(500);

      final SalesSessionController sales =
          SalesSessionController(PosRepository(api));
      await sales.load();

      final Product target = sales.products.firstWhere(
        (Product p) => p.trackStock && p.stock > 5,
      );

      sales.active.addProduct(target);
      final CompletedInvoice invoice = await sales.checkout(<PaymentInput>[
        PaymentInput(method: 'cash', amount: 5000),
      ]);

      await shifts.refreshTotals();

      expect(shifts.totals.invoicesCount, 1);
      expect(shifts.totals.salesTotal, invoice.total);

      // الباقي بيرجع للعميل من نفس الدرج، فاللي دخل فعلًا هو قيمة الفاتورة
      // مش المبلغ اللي الكاشير استلمه.
      expect(invoice.changeDue, closeTo(5000 - invoice.total, 0.01));
      expect(shifts.totals.cashSales, closeTo(invoice.total, 0.01),
          reason: 'الكاش المحصّل = المدفوع ناقص الباقي');
      expect(shifts.totals.expectedCash, closeTo(500 + invoice.total, 0.01));

      sales.dispose();
    });
  });

  group('الباقي والمرتجعات', () {
    test('الباقي اللي بيترد للعميل مبيفضلش في الدرج', () async {
      if (skip()) return;

      await shifts.open(1000);

      final SalesSessionController sales =
          SalesSessionController(PosRepository(api));
      await sales.load();

      final Product target = sales.products.firstWhere(
        (Product p) => p.trackStock && p.price > 0 && p.stock > 5,
      );
      sales.active.addProduct(target);

      final CompletedInvoice invoice = await sales.checkout(<PaymentInput>[
        PaymentInput(method: 'cash', amount: 500),
      ]);

      await shifts.refreshTotals();

      expect(invoice.changeDue, greaterThan(0), reason: 'لازم يبقى فيه باقي');
      expect(shifts.totals.expectedCash, closeTo(1000 + invoice.total, 0.02),
          reason: 'الدرج بياخد قيمة الفاتورة مش المبلغ المستلم');

      sales.dispose();
    });

    test('المرتجع الكاش بينزل من الدرج بنفس المبلغ', () async {
      if (skip()) return;

      await shifts.open(1000);

      final SalesSessionController sales =
          SalesSessionController(PosRepository(api));
      await sales.load();

      final Product target = sales.products.firstWhere(
        (Product p) => p.trackStock && p.price > 0 && p.stock > 5,
      );
      sales.active
        ..addProduct(target)
        ..addProduct(target);

      final CompletedInvoice invoice = await sales.checkout(<PaymentInput>[
        PaymentInput(method: 'cash', amount: 500),
      ]);

      await shifts.refreshTotals();
      final double afterSale = shifts.totals.expectedCash;

      final ReturnsController returns =
          ReturnsController(ReturnsRepository(api));
      await returns.search(invoice.number);

      final ReturnLine line = returns.lines.first;
      returns
        ..setLineSelected(line, true)
        ..setReturnQuantity(line, 2)
        ..setReason('اختبار');

      final CompletedReturn? created = await returns.submit();
      expect(created, isNotNull, reason: returns.error);

      await shifts.refreshTotals();

      expect(afterSale - shifts.totals.expectedCash,
          closeTo(created!.cashRefund, 0.02));
      expect(shifts.totals.expectedCash, closeTo(1000, 0.02),
          reason: 'البيع والمرتجع بيلغوا بعض');

      returns.dispose();
      sales.dispose();
    });
  });

  group('الوردية المقفولة', () {
    test('أرقام التقفيل بتتخزّن كاملة مش بعضها', () async {
      if (skip()) return;

      await shifts.open(1000);

      final SalesSessionController sales =
          SalesSessionController(PosRepository(api));
      await sales.load();
      sales.active.addProduct(
        sales.products.firstWhere(
          (Product p) => p.trackStock && p.price > 0 && p.stock > 5,
        ),
      );
      await sales.checkout(<PaymentInput>[
        PaymentInput(method: 'cash', amount: 500),
      ]);

      final String id = shifts.shift!.id;
      await shifts.addCash(isIn: true, amount: 60, reason: 'إيداع اختبار');
      await shifts.close(countedCash: 0);

      // بنقرا الوردية المقفولة من السيرفر زي ما شاشة السجل بتعمل.
      final ShiftSnapshot snapshot =
          await ShiftRepository(api).fetchById(id);

      expect(snapshot.shift.closing, isNotNull);
      expect(snapshot.totals.cashSales, greaterThan(0),
          reason: 'مبيعات الكاش كانت بتتعرض صفر بعد التقفيل');
      expect(snapshot.totals.cashIn, 60);
      expect(snapshot.totals.expectedCash, greaterThan(0));

      sales.dispose();
    });

    test('إلغاء فاتورة من وردية مقفولة بيترفض', () async {
      if (skip()) return;

      await shifts.open(1000);

      final SalesSessionController sales =
          SalesSessionController(PosRepository(api));
      await sales.load();
      sales.active.addProduct(
        sales.products.firstWhere(
          (Product p) => p.trackStock && p.price > 0 && p.stock > 5,
        ),
      );
      final CompletedInvoice invoice = await sales.checkout(<PaymentInput>[
        PaymentInput(method: 'cash', amount: 500),
      ]);

      await shifts.close(countedCash: 0);
      await shifts.open(1000);

      // الكاش بيخرج من الدرج الحالي، فالإلغاء ممنوع والمرتجع هو الحل.
      final InvoicesRepository invoices = InvoicesRepository(api);

      String? error;
      try {
        await invoices.voidInvoice(invoice.id, reason: 'اختبار');
      } on ApiException catch (e) {
        error = e.message;
      }

      expect(error, isNotNull, reason: 'المفروض يترفض');
      expect(error, contains('مرتجع'));

      sales.dispose();
    });
  });

  group('التقفيل', () {
    test('الدرج المظبوط بيقفل بفرق صفر', () async {
      if (skip()) return;

      await shifts.open(800);

      final String? error =
          await shifts.close(countedCash: shifts.totals.expectedCash);

      expect(error, isNull);
      expect(shifts.isOpen, isFalse);

      final ShiftClosing closing = shifts.lastClosed!.closing!;
      expect(closing.isBalanced, isTrue);
      expect(closing.difference, 0);
    });

    test('العجز بيتسجّل بالسالب', () async {
      if (skip()) return;

      await shifts.open(1000);
      await shifts.close(countedCash: 950);

      final ShiftClosing closing = shifts.lastClosed!.closing!;
      expect(closing.difference, -50);
      expect(closing.isShort, isTrue);
      expect(closing.countedCash, 950);
      expect(closing.expectedCash, 1000);
    });

    test('الزيادة بيتسجّل بالموجب', () async {
      if (skip()) return;

      await shifts.open(1000);
      await shifts.close(countedCash: 1075);

      final ShiftClosing closing = shifts.lastClosed!.closing!;
      expect(closing.difference, 75);
      expect(closing.isShort, isFalse);
    });

    test('بعد التقفيل ينفع تفتح وردية جديدة', () async {
      if (skip()) return;

      await shifts.open(300);
      await shifts.close(countedCash: 300);

      final String? error = await shifts.open(400);

      expect(error, isNull);
      expect(shifts.isOpen, isTrue);
      expect(shifts.openingBalance, 400);
    });
  });
}
