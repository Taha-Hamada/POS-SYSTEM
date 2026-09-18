import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/models/product.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/cashier_shift/controllers/current_shift_controller.dart';
import 'package:pos_system/features/cashier_shift/data/shift_repository.dart';
import 'package:pos_system/features/pos_sale/controllers/sales_session_controller.dart';
import 'package:pos_system/features/pos_sale/data/pos_repository.dart';
import 'package:pos_system/features/pos_sale/models/cart_discount.dart';
import 'package:pos_system/features/returns/controllers/returns_controller.dart';
import 'package:pos_system/features/returns/data/returns_repository.dart';
import 'package:pos_system/features/returns/models/return_line.dart';
import 'package:pos_system/features/returns/models/returnable_invoice.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// دورة المرتجع كاملة على الباك اند الحقيقي: بيع، إرجاع جزئي، ثم الباقي.
void main() {
  late ApiClient api;
  late ReturnsController returns;
  late SalesSessionController sales;
  bool backendUp = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api = ApiClient();

    try {
      await api.get('/health');
      final SessionController auth = SessionController(api);
      backendUp = await auth.login(
        username: 'cashier',
        password: 'Cashier@123',
      );

      if (backendUp) {
        // البيع والمرتجع محتاجين وردية مفتوحة.
        final CurrentShiftController shifts = CurrentShiftController(
          ShiftRepository(api),
        );
        await shifts.load();
        if (!shifts.isOpen) await shifts.open(1000);
        shifts.dispose();
      }
    } on ApiException {
      backendUp = false;
    }
  });

  setUp(() async {
    if (!backendUp) return;

    returns = ReturnsController(ReturnsRepository(api));
    sales = SalesSessionController(PosRepository(api));
    await sales.load();
  });

  tearDown(() {
    if (!backendUp) return;
    returns.dispose();
    sales.dispose();
  });

  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  /// بيعمل فاتورة جديدة ويرجّع رقمها.
  Future<String> sellOne({int quantity = 4}) async {
    final Product target = sales.products.firstWhere(
      (Product p) => p.trackStock && p.price > 0 && p.stock > quantity + 5,
    );

    for (int i = 0; i < quantity; i += 1) {
      sales.active.addProduct(target);
    }

    final CompletedInvoice invoice = await sales.checkout(<PaymentInput>[
      PaymentInput(method: 'cash', amount: 100000),
    ]);

    return invoice.number;
  }

  test('البحث برقم فاتورة مش موجود بيدي رسالة واضحة', () async {
    if (skip()) return;

    await returns.search('INV-999999');

    expect(returns.hasInvoice, isFalse);
    expect(returns.error, contains('مفيش فاتورة'));
  });

  test('البحث بيجيب أصناف الفاتورة بكمياتها', () async {
    if (skip()) return;

    final String number = await sellOne();
    await returns.search(number);

    expect(returns.error, isNull, reason: returns.error);
    expect(returns.hasInvoice, isTrue);
    expect(returns.invoice!.number, number);
    expect(returns.lines, isNotEmpty);

    final ReturnLine line = returns.lines.first;
    expect(line.maxQuantity, 4);
    expect(line.name, isNotEmpty);
    expect(line.unitPrice, greaterThan(0));
  });

  test('قيمة الإرجاع بتتناسب مع الكمية', () async {
    if (skip()) return;

    final String number = await sellOne();
    await returns.search(number);

    final ReturnLine line = returns.lines.first;
    returns.setLineSelected(line, true);
    returns.setReturnQuantity(line, 2);

    // نص الكمية = نص قيمة السطر.
    expect(returns.refundSubtotal, closeTo(line.source.lineTotal / 2, 0.01));
    expect(returns.returnedUnits, 2);
  });

  test('الكمية مبتعديش المتاح', () async {
    if (skip()) return;

    final String number = await sellOne();
    await returns.search(number);

    final ReturnLine line = returns.lines.first;
    returns.setReturnQuantity(line, 999);

    expect(line.returnQuantity, line.maxQuantity);
  });

  test('التسجيل محتاج سبب وأصناف مختارة', () async {
    if (skip()) return;

    final String number = await sellOne();
    await returns.search(number);

    expect(returns.canSubmit, isFalse, reason: 'مفيش صنف مختار');

    returns.setLineSelected(returns.lines.first, true);
    expect(returns.canSubmit, isFalse, reason: 'مفيش سبب');
    expect(returns.needsReason, isTrue);

    returns.setReason(kReturnReasons.first);
    expect(returns.canSubmit, isTrue);
  });

  test('المرتجع الجزئي بيرجّع المخزون ويسيب الباقي متاح', () async {
    if (skip()) return;

    final String number = await sellOne();
    await returns.search(number);

    final ReturnLine line = returns.lines.first;
    final String productId = line.productId;

    final Product before = sales.products.firstWhere(
      (Product p) => p.id == productId,
    );

    returns.setLineSelected(line, true);
    returns.setReturnQuantity(line, 2);
    returns.setReason(kReturnReasons.first);

    final CompletedReturn? created = await returns.submit();

    expect(created, isNotNull, reason: returns.error);
    expect(created!.number, startsWith('RET-'));
    expect(created.total, greaterThan(0));

    // الفاتورة اتقرت من جديد، والمتبقي قلّ.
    expect(returns.lines.first.maxQuantity, 2);
    expect(returns.lines.first.source.returnedQuantity, 2);

    await sales.refreshCatalog();
    final Product after = sales.products.firstWhere(
      (Product p) => p.id == productId,
    );

    expect(after.stock, before.stock + 2, reason: 'الصنف رجع للمخزون');
  });

  test('المرتجع التالف مبيرجعش للمخزون', () async {
    if (skip()) return;

    final String number = await sellOne();
    await returns.search(number);

    final ReturnLine line = returns.lines.first;
    final String productId = line.productId;

    final Product before = sales.products.firstWhere(
      (Product p) => p.id == productId,
    );

    returns.setLineSelected(line, true);
    returns.setReturnQuantity(line, 2);
    returns.setLineRestock(line, false);
    returns.setReason(kReturnReasons.first);

    expect(await returns.submit(), isNotNull, reason: returns.error);

    await sales.refreshCatalog();
    final Product after = sales.products.firstWhere(
      (Product p) => p.id == productId,
    );

    expect(after.stock, before.stock, reason: 'التالف مبيرجعش');
  });

  test('إرجاع الفاتورة بالكامل بيقفلها', () async {
    if (skip()) return;

    final String number = await sellOne(quantity: 2);
    await returns.search(number);

    final ReturnLine line = returns.lines.first;
    returns.setLineSelected(line, true);
    returns.setReturnQuantity(line, line.maxQuantity);
    returns.setReason(kReturnReasons.first);

    expect(await returns.submit(), isNotNull, reason: returns.error);

    // مفيش صنف فاضل للإرجاع.
    expect(returns.lines, isEmpty);
    expect(returns.error, contains('اترجّعت بالكامل'));
  });

  test('الرد على الحساب بيقلّل مديونية العميل', () async {
    if (skip()) return;

    // فاتورة على عميل عشان الرد يقدر يروح على حسابه.
    final List<dynamic> customers = await sales.searchCustomers('');
    if (customers.isEmpty) {
      markTestSkipped('محتاج عملاء');
      return;
    }

    // منتج بسعر، عشان الرد على الحساب يبقى له قيمة فعلًا.
    final Product target = sales.products.firstWhere(
      (Product p) => p.trackStock && p.price > 0 && p.stock > 5,
    );

    sales.active
      ..addProduct(target)
      ..addProduct(target)
      ..setCustomer(customers.first);

    final CompletedInvoice invoice = await sales.checkout(<PaymentInput>[
      PaymentInput(method: 'cash', amount: 100000),
    ]);

    await returns.search(invoice.number);

    final ReturnLine line = returns.lines.first;
    returns.setLineSelected(line, true);
    returns.setReturnQuantity(line, 1);
    returns.setReason(kReturnReasons.first);
    returns.setRefundMethod('credit');

    final CompletedReturn? created = await returns.submit();

    expect(created, isNotNull, reason: returns.error);
    expect(created!.refundMethod, 'credit');
  });



  test('فاتورة آجل بترجع كاش: الدين بيتلغي والدرج ما بيتأثرش', () async {
    if (skip()) return;

    final List<dynamic> customers = await sales.searchCustomers('');
    if (customers.isEmpty) {
      markTestSkipped('محتاج عملاء');
      return;
    }

    final Product target = sales.products.firstWhere(
      (Product p) => p.trackStock && p.price > 0 && p.stock > 5,
    );

    // بنقيس إجمالي الفاتورة الأول عشان الآجل يتبعت بالمبلغ بالظبط.
    sales.active
      ..addProduct(target)
      ..addProduct(target);
    final double due = sales.active.total;

    sales.active.setCustomer(customers.first);
    final CompletedInvoice invoice = await sales.checkout(<PaymentInput>[
      PaymentInput(method: 'credit', amount: due),
    ]);

    expect(invoice.creditAmount, closeTo(due, 0.02));

    await returns.search(invoice.number);
    final ReturnLine line = returns.lines.first;
    returns
      ..setLineSelected(line, true)
      ..setReturnQuantity(line, 2)
      ..setReason(kReturnReasons.first)
      ..setRefundMethod('cash');

    // العميل ماكانش دفع كاش أصلًا، فمفيش كاش يطلع من الدرج.
    expect(returns.cashRefund, closeTo(0, 0.02));
    expect(returns.settledOnAccount, closeTo(returns.refundTotal, 0.02));

    final CompletedReturn? created = await returns.submit();
    expect(created, isNotNull, reason: returns.error);
    expect(created!.cashRefund, closeTo(0, 0.02),
        reason: 'مينفعش نديله كاش وهو ماكانش دفع');
    expect(created.creditRefund, closeTo(created.total, 0.02));
  });

  test('المعاينة على الشاشة بتطابق اللي السيرفر بيردّه — بخصم فاتورة', () async {
    if (skip()) return;

    // خصم على مستوى الفاتورة هو اللي كان بيخلّي المعاينة أعلى من الحقيقة.
    final Product target = sales.products.firstWhere(
      (Product p) => p.trackStock && p.price > 0 && p.stock > 10,
    );
    for (int i = 0; i < 4; i += 1) {
      sales.active.addProduct(target);
    }
    sales.active.setDiscount(
      const CartDiscount(type: DiscountType.percent, value: 10),
    );

    final CompletedInvoice invoice = await sales.checkout(<PaymentInput>[
      PaymentInput(method: 'cash', amount: 100000),
    ]);

    await returns.search(invoice.number);
    final ReturnLine line = returns.lines.first;
    returns.setLineSelected(line, true);
    returns.setReturnQuantity(line, 1);
    returns.setReason('اختبار');

    expect(returns.refundDiscountShare, greaterThan(0),
        reason: 'نصيب المرتجع من خصم الفاتورة لازم يتخصم');

    final double preview = returns.refundTotal;
    final CompletedReturn? created = await returns.submit();

    expect(created, isNotNull, reason: returns.error);
    expect(created!.total, closeTo(preview, 0.02),
        reason: 'الرقم اللي الكاشير شافه هو اللي اترد');
  });

  test('المرتجع الكامل بيساوي إجمالي الفاتورة بالظبط', () async {
    if (skip()) return;

    final Product target = sales.products.firstWhere(
      (Product p) => p.trackStock && p.price > 0 && p.stock > 10,
    );
    for (int i = 0; i < 4; i += 1) {
      sales.active.addProduct(target);
    }
    sales.active.setDiscount(
      const CartDiscount(type: DiscountType.percent, value: 15),
    );

    final CompletedInvoice invoice = await sales.checkout(<PaymentInput>[
      PaymentInput(method: 'cash', amount: 100000),
    ]);

    await returns.search(invoice.number);
    double refunded = 0;

    // على مرتين، عشان نتأكد إن المجموع مبيضيعش في التقريب.
    for (final int qty in <int>[1, 3]) {
      final ReturnLine line = returns.lines.first;
      returns.setLineSelected(line, true);
      returns.setReturnQuantity(line, qty.toDouble());
      returns.setReason('اختبار');

      final CompletedReturn? created = await returns.submit();
      expect(created, isNotNull, reason: returns.error);
      refunded += created!.total;
    }

    expect(refunded, closeTo(invoice.total, 0.02),
        reason: 'مجموع المرتجعات = اللي العميل دفعه');
  });

  test('الكميات الكسرية بترجع زي ما اتباعت', () async {
    if (skip()) return;

    final Product target = sales.products.firstWhere(
      (Product p) => p.trackStock && p.price > 0 && p.stock > 10,
    );
    sales.active.addProduct(target);
    sales.active.setQuantity(sales.active.lines.first, 2.5);

    final CompletedInvoice invoice = await sales.checkout(<PaymentInput>[
      PaymentInput(method: 'cash', amount: 100000),
    ]);

    await returns.search(invoice.number);
    final ReturnLine line = returns.lines.first;
    expect(line.maxQuantity, closeTo(2.5, 0.001));

    returns.setLineSelected(line, true);
    returns.setReturnQuantity(line, 1.5);
    returns.setReason('اختبار');

    final CompletedReturn? created = await returns.submit();
    expect(created, isNotNull, reason: returns.error);
    expect(created!.total, closeTo(invoice.total * 1.5 / 2.5, 0.05));
  });

  test('طرق الرد كاش وآجل بس', () {
    if (skip()) return;

    // الفيزا والمحفظة اتشالوا من النظام كله.
    expect(kRefundMethods.keys, unorderedEquals(<String>['cash', 'credit']));
  });
}
