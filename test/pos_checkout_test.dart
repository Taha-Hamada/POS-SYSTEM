import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/models/customer.dart';
import 'package:pos_system/core/models/product.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/pos_sale/controllers/sales_session_controller.dart';
import 'package:pos_system/features/pos_sale/data/pos_repository.dart';
import 'package:pos_system/features/pos_sale/models/cart_discount.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// دورة البيع كاملة على الباك اند الحقيقي.
///
/// محتاج السيرفر شغال ومتعمله seed، والكاشير لازم يكون له وردية مفتوحة
/// (الاختبار بيفتحها لو مش موجودة). لو السيرفر مقفول الاختبارات بتتخطّى.
void main() {
  late ApiClient api;
  late SalesSessionController session;
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

      if (backendUp) await _ensureOpenShift(api);
    } on ApiException {
      backendUp = false;
    }
  });

  setUp(() async {
    if (!backendUp) return;
    session = SalesSessionController(PosRepository(api));
    await session.load();
  });

  tearDown(() {
    if (backendUp) session.dispose();
  });

  tearDownAll(() => api.dispose());

  bool skip() {
    if (backendUp) return false;
    markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    return true;
  }

  // منتج بسعر، عشان منتج بصفر يطلّع فاتورة بصفر ويكسر حسابات الباقي والخصم.
  Product sellable() => session.products.firstWhere(
    (Product p) => p.trackStock && p.price > 0 && p.stock > 20,
  );

  test('الكتالوج والإعدادات بيتحمّلوا مع بعض', () {
    if (skip()) return;

    expect(session.hasFailed, isFalse, reason: session.errorMessage);
    expect(session.products, isNotEmpty, reason: 'محتاج npm run seed');
    expect(session.categories, isNotEmpty);
    expect(session.settings.taxRate, greaterThan(0));
    expect(session.carts, hasLength(1));
  });

  test('نسبة الضريبة بتوصل للسلة من الإعدادات', () {
    if (skip()) return;

    expect(session.active.taxRate, session.settings.taxRate);
  });

  test('البيع بيخصم المخزون فعلًا', () async {
    if (skip()) return;

    final Product target = sellable();
    final double before = target.stock;

    session.active.addProduct(target);
    session.active.addProduct(target);

    final CompletedInvoice invoice = await session.checkout(<PaymentInput>[
      PaymentInput(method: 'cash', amount: session.active.total + 100),
    ]);

    expect(invoice.number, startsWith('INV-'));
    expect(invoice.total, greaterThan(0));
    expect(invoice.changeDue, greaterThan(0));

    final Product after = session.products.firstWhere(
      (Product p) => p.id == target.id,
    );
    expect(after.stock, before - 2, reason: 'المخزون لازم ينقص بالمباع');
  });

  test('الإجمالي المعروض بيطابق اللي السيرفر بيحصّله', () async {
    if (skip()) return;

    final Product target = sellable();
    session.active
      ..addProduct(target)
      ..addProduct(target)
      ..addProduct(target)
      ..setDiscount(const CartDiscount(type: DiscountType.percent, value: 10));

    final double shown = session.active.total;
    final double shownTax = session.active.tax;

    final CompletedInvoice invoice = await session.checkout(<PaymentInput>[
      PaymentInput(method: 'cash', amount: shown),
    ]);

    expect(invoice.total, shown, reason: 'الكاشير شاف رقم غير المحصّل');
    expect(invoice.taxAmount, shownTax);
  });

  test('السلة بتتفضّى بعد البيع', () async {
    if (skip()) return;

    session.active.addProduct(sellable());
    await session.checkout(<PaymentInput>[
      PaymentInput(method: 'cash', amount: 10000),
    ]);

    expect(session.active.isEmpty, isTrue);
  });

  test('الدفع الناقص بيترفض والسلة بتفضل زي ما هي', () async {
    if (skip()) return;

    session.active.addProduct(sellable());
    final int linesBefore = session.active.lines.length;

    await expectLater(
      session.checkout(<PaymentInput>[
        PaymentInput(method: 'cash', amount: 0.5),
      ]),
      throwsA(isA<ApiException>()),
    );

    expect(
      session.active.lines.length,
      linesBefore,
      reason: 'الرفض ملازمش يضيّع السلة',
    );
  });

  test('الآجل من غير عميل بيترفض برسالة واضحة', () async {
    if (skip()) return;

    session.active.addProduct(sellable());

    try {
      await session.checkout(<PaymentInput>[
        PaymentInput(method: 'credit', amount: session.active.total),
      ]);
      fail('المفروض يرفض الآجل من غير عميل');
    } on ApiException catch (exception) {
      expect(exception.code, 'CREDIT_NEEDS_CUSTOMER');
      expect(exception.message, isNotEmpty);
    }
  });

  group('العملاء', () {
    test('البحث بيرجّع عملاء حقيقيين', () async {
      if (skip()) return;

      final List<Customer> found = await session.searchCustomers('');
      expect(found, isNotEmpty, reason: 'محتاج npm run seed');
      expect(found.first.id, isNotEmpty);
    });

    test('البيع على عميل بيسجّل عليه الفاتورة', () async {
      if (skip()) return;

      final List<Customer> customers = await session.searchCustomers('');
      final Customer customer = customers.first;

      session.active
        ..addProduct(sellable())
        ..setCustomer(customer);

      final CompletedInvoice invoice = await session.checkout(<PaymentInput>[
        PaymentInput(method: 'cash', amount: 10000),
      ]);

      expect(invoice.number, isNotEmpty);
    });
  });

  group('العروض ومستويات العملاء', () {
    Future<ApiClient> adminApi() async {
      final ApiClient admin = ApiClient();
      await SessionController(
        admin,
      ).login(username: 'admin', password: 'Admin@12345');
      return admin;
    }

    test('خصم العرض في الكاشير بيطابق اللي السيرفر حصّله', () async {
      if (skip()) return;

      final ApiClient admin = await adminApi();
      final Product target = sellable();
      final DateTime now = DateTime.now();

      final ApiResponse created = await admin.post(
        '/promotions',
        body: <String, dynamic>{
          'name': 'عرض اختبار ${now.millisecondsSinceEpoch}',
          'type': 'buy_x_get_y',
          'buyQuantity': 2,
          'getQuantity': 1,
          'scope': 'products',
          'products': <String>[target.id],
          'startsAt': now
              .subtract(const Duration(hours: 1))
              .toUtc()
              .toIso8601String(),
          'endsAt': now.add(const Duration(days: 1)).toUtc().toIso8601String(),
        },
      );
      final String promotionId = created.object['id'] as String;

      try {
        await session.load();
        expect(session.promotions.any((p) => p.id == promotionId), isTrue);

        session.active
          ..addProduct(target)
          ..addProduct(target)
          ..addProduct(target);

        // تلات قطع = مجموعة كاملة، فقطعة منهم مجانية.
        expect(session.active.promotionDiscount, target.price);

        final double shown = session.active.total;
        final CompletedInvoice invoice = await session.checkout(<PaymentInput>[
          PaymentInput(method: 'cash', amount: shown),
        ]);

        expect(invoice.total, shown, reason: 'الكاشير شاف خصم غير اللي اتحسب');
      } finally {
        await admin.patch(
          '/promotions/$promotionId/active',
          body: <String, bool>{'isActive': false},
        );
        admin.dispose();
      }
    });

  });

  test('البحث في الكتالوج بيشتغل بالاسم والكود', () {
    if (skip()) return;

    final Product target = session.products.first;

    expect(
      session.search(target.name).map((Product p) => p.id),
      contains(target.id),
    );
    expect(
      session.search(target.sku).map((Product p) => p.id),
      contains(target.id),
    );
    expect(session.search('لا-يوجد-كده-أبدا'), isEmpty);
  });

  test('مسح باركود بيلاقي المنتج محليًا ومن السيرفر', () async {
    if (skip()) return;

    final Product target = session.products.firstWhere(
      (Product p) => p.barcode != null && p.barcode!.isNotEmpty,
    );

    expect((await session.productByBarcode(target.barcode!))?.id, target.id);
    expect(await session.productByBarcode('0000000000'), isNull);
  });
}

/// الباك اند بيرفض البيع من غير وردية مفتوحة، فبنفتح واحدة لو مفيش.
Future<void> _ensureOpenShift(ApiClient api) async {
  final ApiResponse current = await api.get('/shifts/current');
  if (current.data != null) return;

  await api.post('/shifts', body: <String, dynamic>{'openingBalance': 500});
}
