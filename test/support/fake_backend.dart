import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:http/testing.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:pos_system/features/cashier_shift/controllers/current_shift_controller.dart';
import 'package:pos_system/features/cashier_shift/data/shift_repository.dart';
import 'package:pos_system/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// باك اند مزيّف لاختبارات الواجهة.
///
/// اختبارات الواجهة لازم تشتغل من غير سيرفر شغال، وفي نفس الوقت الشاشات بقت
/// بتقرأ من الـ API. فبنرد هنا بردود بنفس شكل الباك اند الحقيقي بالظبط.
class FakeBackend {
  FakeBackend({List<Map<String, dynamic>>? products, List<Map<String, dynamic>>? categories})
      : categories = categories ?? _defaultCategories,
        products = products ?? _defaultProducts;

  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> heldInvoices = <Map<String, dynamic>>[];

  /// الوردية المفتوحة، أو null لو الكاشير مقفول.
  Map<String, dynamic>? currentShift;

  Map<String, dynamic> settings = <String, dynamic>{
    'storeName': 'متجر الاختبار',
    'currency': 'EGP',
    'taxRate': 0.14,
    'pointsPerCurrency': 1,
    'allowNegativeStock': false,
    'requireCustomerForCredit': true,
    'requireOpenShift': false,
  };

  /// بيفتح وردية بالأرقام اللي الاختبار محتاجها.
  ///
  /// الأرقام بتتحط صراحة مش بتتحسب، عشان الاختبار يعرف يتوقع رقم بعينه.
  void openShift(
    double openingBalance, {
    double cashSales = 0,
    double cashIn = 0,
    double cashOut = 0,
    double salesTotal = 0,
    int invoicesCount = 0,
  }) {
    currentShift = <String, dynamic>{
      'shift': <String, dynamic>{
        'id': 'sh-1',
        'number': 'SH-00001',
        'status': 'open',
        'openingBalance': openingBalance,
        'openedAt': DateTime.now().toIso8601String(),
        'cashier': <String, dynamic>{'id': 'u1', 'name': 'مستخدم الاختبار'},
        'branch': <String, dynamic>{'id': 'b1', 'name': 'الفرع الرئيسي'},
      },
      'totals': <String, dynamic>{
        'salesTotal': salesTotal,
        'invoicesCount': invoicesCount,
        'cashSales': cashSales,
        'cashIn': cashIn,
        'cashOut': cashOut,
        'expectedCash': openingBalance + cashSales + cashIn - cashOut,
        'byMethod': <String, dynamic>{},
      },
    };
  }

  Map<String, dynamic> _closeShift(double countedCash) {
    final Map<String, dynamic> shift =
        currentShift!['shift'] as Map<String, dynamic>;
    final Map<String, dynamic> totals =
        currentShift!['totals'] as Map<String, dynamic>;

    final double expected = (totals['expectedCash'] as num).toDouble();

    final Map<String, dynamic> closed = <String, dynamic>{
      ...shift,
      'status': 'closed',
      'closedAt': DateTime.now().toIso8601String(),
      'closing': <String, dynamic>{
        'countedCash': countedCash,
        'expectedCash': expected,
        'difference': countedCash - expected,
        'salesTotal': totals['salesTotal'],
        'invoicesCount': totals['invoicesCount'],
      },
    };

    currentShift = null;
    return closed;
  }

  /// المسارات اللي اتطلبت — مفيدة للتأكد إن الشاشة طلبت اللي المفروض تطلبه.
  final List<String> requestedPaths = <String>[];

  ApiClient client() {
    final ApiClient api = ApiClient(httpClient: MockClient(_handle));
    api.setTokens(accessToken: 'fake-access', refreshToken: 'fake-refresh');
    return api;
  }

  Future<http.Response> _handle(http.Request request) async {
    final String path = request.url.path;
    requestedPaths.add(path);

    // ‏‎/auth/me بيرجّع المستخدم لوحده، والدخول بيرجّعه ومعاه التوكنات.
    if (path.endsWith('/auth/me')) return _ok(_session['user'] as Object);
    if (path.endsWith('/auth/login')) return _ok(_session);

    if (path.endsWith('/products')) {
      return _page(products);
    }

    if (path.endsWith('/settings')) return _ok(settings);

    // مفيش وردية مفتوحة افتراضيًا؛ الاختبار بيقدر يفتحها بـopenShift().
    if (path.endsWith('/shifts/current')) return _ok2(currentShift);

    if (path.endsWith('/shifts') && request.method == 'POST') {
      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      openShift((body['openingBalance'] as num).toDouble());
      return _ok(currentShift!['shift'] as Object);
    }

    if (path.endsWith('/close')) {
      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      final Map<String, dynamic> closed = _closeShift(
        (body['countedCash'] as num).toDouble(),
      );
      return _ok(closed);
    }

    if (path.endsWith('/cash')) return _ok(currentShift!['shift'] as Object);

    if (path.contains('/shifts/')) return _ok2(currentShift);

    // المعلّقات بتتخزن في الذاكرة عشان اختبارات التعليق تشتغل من غير سيرفر.
    if (path.endsWith('/invoices/held') && request.method == 'GET') {
      return _page(heldInvoices);
    }

    if (path.endsWith('/invoices/hold')) {
      final Map<String, dynamic> held = _invoiceFrom(request, held: true);
      heldInvoices.add(held);
      return _ok(held);
    }

    if (path.endsWith('/invoices') && request.method == 'POST') {
      return _ok(_invoiceFrom(request));
    }

    if (path.endsWith('/categories')) {
      return _page(categories);
    }

    // أي مسار مش متغطّى بيرجع قايمة فاضية بدل ما يكسر الاختبار،
    // عشان الشاشات اللي لسه على البيانات الوهمية تفضل شغالة.
    return _page(<Map<String, dynamic>>[]);
  }

  /// بيبني فاتورة زي ما السيرفر بيرجّعها، بحساب مبسّط كفاية للاختبارات.
  Map<String, dynamic> _invoiceFrom(http.Request request, {bool held = false}) {
    final Map<String, dynamic> body =
        jsonDecode(request.body) as Map<String, dynamic>;

    final List<dynamic> lines = body['lines'] as List<dynamic>? ?? <dynamic>[];
    final double taxRate = (settings['taxRate'] as num).toDouble();

    double subtotal = 0;
    final List<Map<String, dynamic>> stored = <Map<String, dynamic>>[];

    for (final dynamic raw in lines) {
      final Map<String, dynamic> line = raw as Map<String, dynamic>;
      final Map<String, dynamic> product = products.firstWhere(
        (Map<String, dynamic> p) => p['id'] == line['product'],
        orElse: () => products.first,
      );

      final int quantity = (line['quantity'] as num).toInt();
      final double price = (product['price'] as num).toDouble();
      subtotal += price * quantity;

      stored.add(<String, dynamic>{
        'product': product['id'],
        'name': product['name'],
        'quantity': quantity,
        'unitPrice': price,
        'lineTotal': price * quantity,
      });
    }

    final double tax = subtotal * taxRate;
    final double total = subtotal + tax;

    final double paid = (body['payments'] as List<dynamic>? ?? <dynamic>[]).fold<double>(
      0,
      (double s, dynamic p) =>
          s + ((p as Map<String, dynamic>)['amount'] as num).toDouble(),
    );

    _invoiceCounter += 1;

    return <String, dynamic>{
      'id': 'inv-$_invoiceCounter',
      'number':
          held ? null : 'INV-${_invoiceCounter.toString().padLeft(6, '0')}',
      'label': body['label'],
      'lines': stored,
      'subtotal': subtotal,
      'taxAmount': tax,
      'total': total,
      'paidAmount': paid,
      'changeDue': paid > total ? paid - total : 0,
      'creditAmount': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'customer': null,
    };
  }

  int _invoiceCounter = 0;

  /// زي [_ok] بس بيسمح بقيمة فاضية، للمسارات اللي ردها ممكن يكون null.
  static http.Response _ok2(Object? data) => http.Response(
        jsonEncode(<String, dynamic>{'success': true, 'message': null, 'data': data}),
        200,
        headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
      );

  static http.Response _ok(Object data) => http.Response(
        jsonEncode(<String, dynamic>{'success': true, 'message': null, 'data': data}),
        200,
        headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
      );

  static http.Response _page(List<Map<String, dynamic>> items) => http.Response(
        jsonEncode(<String, dynamic>{
          'success': true,
          'message': null,
          'data': items,
          'meta': <String, dynamic>{
            'pagination': <String, dynamic>{
              'page': 1,
              'limit': 100,
              'total': items.length,
              'pages': 1,
              'hasNext': false,
              'hasPrev': false,
            },
          },
        }),
        200,
        headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
      );

  static final Map<String, dynamic> _session = <String, dynamic>{
    'user': <String, dynamic>{
      'id': 'u1',
      'name': 'مستخدم الاختبار',
      'username': 'tester',
      'role': 'admin',
      'branch': <String, dynamic>{'id': 'b1', 'name': 'الفرع الرئيسي'},
      'permissions': <String>[],
    },
    'tokens': <String, String>{
      'accessToken': 'fake-access',
      'refreshToken': 'fake-refresh',
    },
  };

  static final List<Map<String, dynamic>> _defaultCategories = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'c1',
      'name': 'مشروبات',
      'icon': 'local_drink',
      'color': '#3B82F6',
      'productsCount': 2,
      'isActive': true,
    },
    <String, dynamic>{
      'id': 'c2',
      'name': 'وجبات خفيفة',
      'icon': 'fastfood',
      'color': '#F59E0B',
      'productsCount': 1,
      'isActive': true,
    },
  ];

  static Map<String, dynamic> product({
    required String id,
    required String name,
    required String sku,
    String categoryId = 'c1',
    String categoryName = 'مشروبات',
    double price = 10,
    double cost = 6,
    int stock = 50,
    int minStock = 10,
    bool isActive = true,
  }) =>
      <String, dynamic>{
        'id': id,
        'name': name,
        'sku': sku,
        'barcode': null,
        'category': <String, dynamic>{
          'id': categoryId,
          'name': categoryName,
          'icon': 'local_drink',
          'color': '#3B82F6',
        },
        'brand': '',
        'unit': 'قطعة',
        'price': price,
        'cost': cost,
        'stock': stock,
        'reserved': 0,
        'minStock': minStock,
        'effectiveMinStock': minStock,
        'trackStock': true,
        'isTaxable': true,
        'isActive': isActive,
        'expiryDate': null,
        'imageUrl': null,
        'colorIndex': 0,
      };

  static final List<Map<String, dynamic>> _defaultProducts = <Map<String, dynamic>>[
    product(id: 'p1', name: 'بيبسي كانز', sku: 'PEP-330', stock: 80),
    product(id: 'p2', name: 'مياه معدنية', sku: 'WTR-600', stock: 4, minStock: 20),
    // منتج متوقّف — بيغذي تبويب «غير نشطة».
    product(
      id: 'p3',
      name: 'شيبسي جبنة',
      sku: 'CHP-CHS',
      categoryId: 'c2',
      categoryName: 'وجبات خفيفة',
      stock: 0,
      isActive: false,
    ),
    // منتج شغّال بس خلص من المخزن — بيغذي شارة «نفد المخزون».
    product(
      id: 'p4',
      name: 'عصير مانجو',
      sku: 'JUC-MNG',
      stock: 0,
      minStock: 12,
    ),
  ];
}

/// بيلفّ شاشة واحدة بالـproviders اللي محتاجاها، عشان اختبارات الواجهة
/// تبني شاشة بعينها من غير ما تشغّل التطبيق كله.
Future<Widget> wrapScreen(Widget child, {FakeBackend? backend}) async {
  final FakeBackend fake = backend ?? FakeBackend();
  final ApiClient api = fake.client();
  final SessionController session = SessionController(api);

  await session.login(username: 'tester', password: 'x');

  final CurrentShiftController shifts =
      CurrentShiftController(ShiftRepository(api));
  await shifts.load();

  return MultiProvider(
    providers: <SingleChildWidget>[
      ChangeNotifierProvider<SessionController>.value(value: session),
      ChangeNotifierProvider<CurrentShiftController>.value(value: shifts),
      Provider<ApiClient>.value(value: api),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    ),
  );
}
