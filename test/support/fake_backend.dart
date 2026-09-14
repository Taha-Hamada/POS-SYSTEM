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

  /// عملاء بأرصدة مختلفة: واحد عليه مديونية وواحد رصيده صفر.
  final List<Map<String, dynamic>> customers = <Map<String, dynamic>>[
    _customer(id: 'cu1', name: 'محمد أحمد', phone: '01001112222', balance: -500,
        tier: 'gold', points: 320, orders: 12),
    _customer(id: 'cu2', name: 'هدى إبراهيم', phone: '01003334444'),
  ];

  /// المصروفات المسجّلة — الاختبارات بتضيف عليها والشاشة بتقراها.
  final List<Map<String, dynamic>> expenses = <Map<String, dynamic>>[
    _expense(id: 'ex1', number: 'EXP-00001', category: 'كهرباء', amount: 1200),
    _expense(
      id: 'ex2',
      number: 'EXP-00002',
      category: 'إيجار',
      amount: 8000,
      status: 'approved',
    ),
    _expense(
      id: 'ex3',
      number: 'EXP-00003',
      category: 'صيانة',
      amount: 450,
      branchId: 'b2',
      branchName: 'فرع المعادي',
    ),
  ];

  static Map<String, dynamic> _expense({
    required String id,
    required String number,
    required String category,
    required double amount,
    String status = 'pending',
    String branchId = 'b1',
    String branchName = 'الفرع الرئيسي',
    String method = 'cash',
    String note = 'ملاحظة الاختبار',
  }) =>
      <String, dynamic>{
        'id': id,
        'number': number,
        'category': category,
        'amount': amount,
        'status': status,
        'paymentMethod': method,
        'date': DateTime.now().toIso8601String(),
        'branch': <String, dynamic>{'id': branchId, 'name': branchName},
        'note': note,
        'createdBy': <String, dynamic>{'id': 'u2', 'name': 'موظف الاختبار'},
      };

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

  /// سلسلة مبيعات بأرقام ثابتة: 1000 لكل يوم.
  List<Map<String, dynamic>> _series(int days) {
    final DateTime today = DateTime.now();

    return <Map<String, dynamic>>[
      for (int i = days - 1; i >= 0; i -= 1)
        <String, dynamic>{
          'date': today
              .subtract(Duration(days: i))
              .toIso8601String()
              .substring(0, 10),
          'sales': 1000,
          'tax': 140,
          'profit': 250,
          'invoices': 8,
        },
    ];
  }

  /// مبيعات كل فرع — الأرقام ثابتة عشان الاختبار يعرف يتوقعها.
  static final List<Map<String, dynamic>> _branches = <Map<String, dynamic>>[
    <String, dynamic>{'id': 'b1', 'name': 'الفرع الرئيسي', 'code': 'MAIN'},
    <String, dynamic>{'id': 'b2', 'name': 'فرع المعادي', 'code': 'MAAD'},
  ];

  /// سجلات مخزون مبنية من المنتجات، مع فلترة الحالة زي السيرفر.
  List<Map<String, dynamic>> _stockFor(String? status) {
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[
      for (final Map<String, dynamic> p in products)
        <String, dynamic>{
          '_id': 'st-${p['id']}',
          'quantity': p['stock'],
          'reserved': 0,
          'effectiveMinStock': p['minStock'],
          'available': p['stock'],
          'updatedAt': DateTime.now().toIso8601String(),
          'product': <String, dynamic>{
            '_id': p['id'],
            'name': p['name'],
            'sku': p['sku'],
            'unit': p['unit'],
            'cost': p['cost'],
            'price': p['price'],
            'minStock': p['minStock'],
            'category': <String, dynamic>{
              'name': 'مشروبات',
              'icon': 'local_drink',
              'color': '#3B82F6',
            },
          },
          'branch': <String, dynamic>{'id': 'b1', 'name': 'الفرع الرئيسي'},
        },
    ];

    int qty(Map<String, dynamic> r) => (r['quantity'] as num).toInt();
    int min(Map<String, dynamic> r) => (r['effectiveMinStock'] as num).toInt();

    return switch (status) {
      'out' => all.where((Map<String, dynamic> r) => qty(r) <= 0).toList(),
      'low' => all
          .where((Map<String, dynamic> r) => qty(r) > 0 && qty(r) <= min(r))
          .toList(),
      'ok' => all.where((Map<String, dynamic> r) => qty(r) > min(r)).toList(),
      _ => all,
    };
  }

  static const Map<String, double> _branchSales = <String, double>{
    'b1': 60000,
    'b2': 40000,
  };

  static const Map<String, String> _branchNames = <String, String>{
    'b1': 'الفرع الرئيسي',
    'b2': 'فرع المعادي',
  };

  /// داشبورد بأرقام ثابتة: المبيعات = 1000 لكل يوم في الفترة.
  Map<String, dynamic> _dashboard({required int days, String? branchId}) {
    const double perDay = 1000;

    final double scale = branchId == null
        ? 1
        : (_branchSales[branchId] ?? 0) /
            _branchSales.values.fold<double>(0, (double s, double v) => s + v);

    final double sales = perDay * days * scale;
    final DateTime today = DateTime.now();

    return <String, dynamic>{
      'today': <String, dynamic>{
        'sales': perDay * scale,
        'invoices': 8,
        'profit': perDay * scale * 0.25,
        'tax': 0,
      },
      'period': <String, dynamic>{
        'days': days,
        'sales': sales,
        'invoices': days * 8,
        'profit': sales * 0.25,
        'discounts': 0,
        'returns': 0,
        'expenses': 0,
        'netProfit': sales * 0.25,
        'averageTicket': sales / (days * 8),
      },
      'previous': <String, dynamic>{
        'sales': sales * 0.9,
        'invoices': days * 7,
        'profit': sales * 0.9 * 0.25,
        'averageTicket': (sales * 0.9) / (days * 7),
      },
      'paymentMethods': <String, dynamic>{
        'cash': <String, dynamic>{'amount': sales * 0.6, 'count': 10},
        'card': <String, dynamic>{'amount': sales * 0.4, 'count': 5},
      },
      'series': <Map<String, dynamic>>[
        for (int i = days - 1; i >= 0; i -= 1)
          <String, dynamic>{
            'date': today
                .subtract(Duration(days: i))
                .toIso8601String()
                .substring(0, 10),
            'sales': perDay * scale,
            'profit': perDay * scale * 0.25,
            'invoices': 8,
          },
      ],
      'topProducts': <Map<String, dynamic>>[
        for (final Map<String, dynamic> p in products.take(3))
          <String, dynamic>{
            'product': p['id'],
            'name': p['name'],
            'sku': p['sku'],
            'units': 20,
            'revenue': (p['price'] as num) * 20,
            'profit': (p['price'] as num) * 8,
          },
      ],
      'lowStock': <Map<String, dynamic>>[],
      'inventory': <String, dynamic>{
        'items': products.length,
        'units': 200,
        'costValue': 5000,
        'retailValue': 9000,
        'expectedProfit': 4000,
        'outOfStock': 1,
      },
      'receivables': <String, dynamic>{'total': 1200, 'count': 2},
      'payables': <String, dynamic>{'total': 800, 'count': 1},
      'expiringSoon': <Map<String, dynamic>>[],
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

    if (path.endsWith('/inventory/stock')) {
      final String? status = request.url.queryParameters['status'];
      return _page(_stockFor(status));
    }

    if (path.endsWith('/inventory/summary')) {
      return _ok(<String, dynamic>{
        'items': products.length,
        'units': 200,
        'value': 5000,
        'retailValue': 9000,
        'outOfStock': 1,
        'lowStock': 1,
        'nearExpiry': 0,
      });
    }

    if (path.endsWith('/inventory/movements')) {
      return _page(<Map<String, dynamic>>[]);
    }

    // ‏‎/reports/branches بينتهي بـ‎/branches كمان، فبنستثنيه هنا.
    if (path.endsWith('/branches') && !path.contains('/reports/')) {
      return _page(_branches);
    }

    if (path.endsWith('/expenses/summary')) {
      final List<Map<String, dynamic>> matching = _filteredExpenses(request);
      final Map<String, double> byCategory = <String, double>{};

      for (final Map<String, dynamic> e in matching) {
        final String category = e['category'] as String;
        byCategory[category] =
            (byCategory[category] ?? 0) + (e['amount'] as num).toDouble();
      }

      final double total =
          byCategory.values.fold<double>(0, (double s, double v) => s + v);

      return _ok(<String, dynamic>{
        'total': total,
        'categories': <Map<String, dynamic>>[
          for (final MapEntry<String, double> entry in byCategory.entries)
            <String, dynamic>{
              'category': entry.key,
              'total': entry.value,
              'count': 1,
              'share': total == 0 ? 0 : (entry.value / total) * 100,
            },
        ],
      });
    }

    if (path.endsWith('/expenses') && request.method == 'GET') {
      return _page(_filteredExpenses(request));
    }

    if (path.endsWith('/expenses') && request.method == 'POST') {
      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;

      _expenseCounter += 1;
      final Map<String, dynamic> created = _expense(
        id: 'ex-new-$_expenseCounter',
        number: 'EXP-${(100 + _expenseCounter).toString().padLeft(5, '0')}',
        category: body['category'] as String,
        amount: (body['amount'] as num).toDouble(),
        method: body['paymentMethod'] as String? ?? 'cash',
        note: body['note'] as String? ?? '',
      );

      expenses.insert(0, created);
      return _ok(created);
    }

    if (path.contains('/expenses/') && path.endsWith('/review')) {
      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      final String id = path.split('/expenses/').last.split('/').first;

      final Map<String, dynamic> expense =
          expenses.firstWhere((Map<String, dynamic> e) => e['id'] == id);
      expense['status'] =
          (body['approve'] as bool) ? 'approved' : 'rejected';

      return _ok(expense);
    }

    if (path.contains('/expenses/') && request.method == 'DELETE') {
      final String id = path.split('/expenses/').last;
      expenses.removeWhere((Map<String, dynamic> e) => e['id'] == id);
      return _ok(<String, dynamic>{'id': id, 'deleted': true});
    }

    if (path.endsWith('/customers/receivables')) {
      return _ok(<String, dynamic>{'total': 500, 'count': 1});
    }

    if (path.endsWith('/ledger')) return _page(_ledger);
    if (path.endsWith('/loyalty')) return _page(_loyalty);

    if (path.endsWith('/customers') && request.method == 'GET') {
      return _page(customers);
    }

    // ملف عميل واحد — بيتطلب بمعرّفه.
    if (path.contains('/customers/')) {
      final String id = path.split('/').last;
      final Map<String, dynamic>? found = customers
          .cast<Map<String, dynamic>?>()
          .firstWhere((Map<String, dynamic>? c) => c!['id'] == id,
              orElse: () => null);

      if (found == null) {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'success': false,
            'message': 'العميل غير موجود',
            'error': <String, dynamic>{'code': 'NOT_FOUND'},
          }),
          404,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }

      return _ok(found);
    }

    if (path.endsWith('/invoices') && request.method == 'GET') {
      return _page(<Map<String, dynamic>>[]);
    }

    if (path.endsWith('/reports/dashboard')) {
      final int days =
          int.tryParse(request.url.queryParameters['days'] ?? '30') ?? 30;
      final String? branch = request.url.queryParameters['branch'];
      return _ok(_dashboard(days: days, branchId: branch));
    }

    // البحث برقم الفاتورة ثم أصنافها المتاح إرجاعها.
    if (path.contains('/invoices/number/')) {
      return _ok(<String, dynamic>{'id': 'inv-1', 'number': 'INV-000001'});
    }

    if (path.contains('/returns/returnable/')) {
      return _ok(<String, dynamic>{
        'invoice': <String, dynamic>{
          'id': 'inv-1',
          'number': 'INV-000001',
          'total': 114,
          'status': 'completed',
          'createdAt': DateTime.now().toIso8601String(),
          'customer': null,
        },
        'ageDays': 2,
        'isWithinWindow': true,
        'windowDays': 30,
        'lines': <Map<String, dynamic>>[
          for (final Map<String, dynamic> p in products.take(2))
            <String, dynamic>{
              'invoiceLine': 'line-${p['id']}',
              'product': p['id'],
              'name': p['name'],
              'sku': p['sku'],
              'unit': p['unit'],
              'soldQuantity': 3,
              'returnedQuantity': 0,
              'remainingQuantity': 3,
              'unitPrice': p['price'],
              'lineTotal': (p['price'] as num) * 3,
            },
        ],
      });
    }

    if (path.endsWith('/returns') && request.method == 'POST') {
      return _ok(<String, dynamic>{
        'id': 'ret-1',
        'number': 'RET-000001',
        'total': 34.2,
        'taxAmount': 4.2,
        'refundMethod': 'cash',
      });
    }

    if (path.endsWith('/reports/sales-series')) {
      final int days =
          int.tryParse(request.url.queryParameters['days'] ?? '30') ?? 30;
      return _ok(_series(days));
    }

    if (path.endsWith('/reports/by-category')) {
      return _ok(<String, dynamic>{
        'total': 30000,
        'categories': <Map<String, dynamic>>[
          for (final Map<String, dynamic> c in categories)
            <String, dynamic>{
              'category': c['id'],
              'name': c['name'],
              'icon': c['icon'],
              'color': c['color'],
              'units': 120,
              'revenue': 15000,
              'profit': 4000,
              'share': 50,
            },
        ],
      });
    }

    if (path.endsWith('/reports/top-products')) {
      return _ok(<Map<String, dynamic>>[
        for (final Map<String, dynamic> p in products.take(3))
          <String, dynamic>{
            'product': p['id'],
            'name': p['name'],
            'sku': p['sku'],
            'units': 20,
            'revenue': (p['price'] as num) * 20,
            'profit': (p['price'] as num) * 8,
          },
      ]);
    }

    if (path.endsWith('/reports/cashiers')) {
      return _ok(<Map<String, dynamic>>[
        <String, dynamic>{
          'cashier': 'u1',
          'name': 'مستخدم الاختبار',
          'username': 'tester',
          'invoices': 40,
          'sales': 30000,
          'discounts': 500,
          'averageTicket': 750,
        },
      ]);
    }

    if (path.endsWith('/reports/tax')) {
      return _ok(<String, dynamic>{
        'taxRate': settings['taxRate'],
        'collected': 4200,
        'paid': 1200,
        'net': 3000,
        'purchasesReceived': 8571,
        'months': <Map<String, dynamic>>[
          <String, dynamic>{
            'month': '2026-09',
            'taxableBase': 30000,
            'tax': 4200,
            'invoices': 240,
          },
        ],
      });
    }

    if (path.endsWith('/reports/inventory-by-category')) {
      return _ok(<Map<String, dynamic>>[
        for (final Map<String, dynamic> c in categories)
          <String, dynamic>{
            'category': c['id'],
            'name': c['name'],
            'icon': c['icon'],
            'color': c['color'],
            'items': 3,
            'units': 120,
            'cost': 2500,
            'retail': 4500,
            'expectedProfit': 2000,
          },
      ]);
    }

    if (path.endsWith('/reports/branches')) {
      return _ok(<String, dynamic>{
        'total': _branchSales.values.fold<double>(0, (double s, double v) => s + v),
        'branches': <Map<String, dynamic>>[
          for (final MapEntry<String, double> entry in _branchSales.entries)
            <String, dynamic>{
              'branch': entry.key,
              'name': _branchNames[entry.key],
              'sales': entry.value,
              'profit': entry.value * 0.25,
              'invoices': 40,
              'share': (entry.value / 100000) * 100,
            },
        ],
      });
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
  int _expenseCounter = 0;

  /// بيطبّق فلاتر المصروفات زي السيرفر: البند والفرع والحالة والبحث.
  List<Map<String, dynamic>> _filteredExpenses(http.Request request) {
    final Map<String, String> query = request.url.queryParameters;
    final String? category = query['category'];
    final String? branch = query['branch'];
    final String? status = query['status'];
    final String? search = query['search'];

    return expenses.where((Map<String, dynamic> e) {
      if (category != null && e['category'] != category) return false;
      if (status != null && e['status'] != status) return false;
      if (branch != null &&
          (e['branch'] as Map<String, dynamic>)['id'] != branch) {
        return false;
      }
      if (search == null) return true;

      return '${e['number']}${e['note']}${e['category']}'.contains(search);
    }).toList();
  }

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

  static Map<String, dynamic> _customer({
    required String id,
    required String name,
    required String phone,
    double balance = 0,
    String tier = 'regular',
    int points = 0,
    int orders = 0,
  }) =>
      <String, dynamic>{
        'id': id,
        'name': name,
        'phone': phone,
        'email': null,
        'tier': tier,
        'balance': balance,
        'creditLimit': 2000,
        'points': points,
        'totalPurchases': orders * 250,
        'ordersCount': orders,
        'lastVisitAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };

  static final List<Map<String, dynamic>> _ledger = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'lg1',
      'type': 'sale',
      'amount': -500,
      'balanceAfter': -500,
      'createdAt': DateTime.now().toIso8601String(),
      'note': 'فاتورة بيع',
      'branch': <String, dynamic>{'name': 'الفرع الرئيسي'},
    },
  ];

  static final List<Map<String, dynamic>> _loyalty = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'ly1',
      'type': 'earn',
      'points': 320,
      'balanceAfter': 320,
      'valueAmount': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'note': 'نقط فاتورة',
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
