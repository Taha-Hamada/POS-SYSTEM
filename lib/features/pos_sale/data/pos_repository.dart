import '../../../core/api/api_client.dart';
import '../../../core/models/category.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/product.dart';
import '../../../core/models/store_settings.dart';
import '../models/held_invoice.dart';

/// كل ما تحتاجه شاشة الكاشير من السيرفر.
class PosRepository {
  const PosRepository(this._api);

  final ApiClient _api;

  static const int _pageSize = 100;

  /// الكتالوج بيتحمّل مرة واحدة أول ما الشاشة تفتح.
  /// الكاشير بيدوّر ويضغط بسرعة، فاستنى طلب مع كل حرف مش مقبول هنا.
  Future<List<Product>> fetchProducts({String? branchId}) async {
    final List<Product> products = <Product>[];
    int page = 1;

    while (true) {
      final ApiResponse response = await _api.get(
        '/products',
        query: <String, dynamic>{
          'page': page,
          'limit': _pageSize,
          'branch': branchId,
          'isActive': 'true',
        },
      );

      products.addAll(response.list.map(Product.fromJson));

      if (!response.hasNext) break;
      page += 1;
    }

    return products;
  }

  Future<List<Category>> fetchCategories() async {
    final ApiResponse response = await _api.get(
      '/categories',
      query: <String, dynamic>{'limit': _pageSize, 'isActive': 'true'},
    );

    return response.list.map(Category.fromJson).toList();
  }

  Future<StoreSettings> fetchSettings() async {
    final ApiResponse response = await _api.get('/settings');
    return StoreSettings.fromJson(response.object);
  }

  /// مسح باركود — بيرجّع null لو مفيش منتج بالكود ده.
  Future<Product?> findByBarcode(String barcode, {String? branchId}) async {
    final ApiResponse response = await _api.get(
      '/products/barcode/$barcode',
      query: <String, dynamic>{'branch': branchId},
    );

    return Product.fromJson(response.object);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final ApiResponse response = await _api.get(
      '/customers',
      query: <String, dynamic>{'search': query, 'limit': 20, 'isActive': 'true'},
    );

    return response.list.map(Customer.fromJson).toList();
  }

  Future<Customer> createCustomer({
    required String name,
    required String phone,
  }) async {
    final ApiResponse response = await _api.post(
      '/customers',
      body: <String, String>{'name': name, 'phone': phone},
    );

    return Customer.fromJson(response.object);
  }

  // ── الفواتير ───────────────────────────────────────────────────────────────

  /// اعتماد فاتورة بيع. بيرجّع الفاتورة زي ما السيرفر حسبها،
  /// فالرقم المطبوع على الإيصال هو الرقم المحصّل مش تقدير الجهاز.
  Future<CompletedInvoice> checkout({
    required List<InvoiceLineInput> lines,
    required List<PaymentInput> payments,
    String? customerId,
    DiscountInput? discount,
    String? note,
  }) async {
    final ApiResponse response = await _api.post(
      '/invoices',
      body: <String, dynamic>{
        'lines': lines.map((InvoiceLineInput l) => l.toJson()).toList(),
        'payments': payments.map((PaymentInput p) => p.toJson()).toList(),
        if (customerId != null && customerId.isNotEmpty) 'customer': customerId,
        if (discount != null) 'discount': discount.toJson(),
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return CompletedInvoice.fromJson(response.object);
  }

  /// تعليق فاتورة على السيرفر — بيحجز الرصيد عشان محدش يبيعه.
  Future<HeldInvoice> hold({
    required List<InvoiceLineInput> lines,
    String? customerId,
    DiscountInput? discount,
    String? label,
  }) async {
    final ApiResponse response = await _api.post(
      '/invoices/hold',
      body: <String, dynamic>{
        'lines': lines.map((InvoiceLineInput l) => l.toJson()).toList(),
        if (customerId != null && customerId.isNotEmpty) 'customer': customerId,
        if (discount != null) 'discount': discount.toJson(),
        if (label != null && label.isNotEmpty) 'label': label,
      },
    );

    return HeldInvoice.fromJson(response.object);
  }

  Future<List<HeldInvoice>> fetchHeld() async {
    final ApiResponse response = await _api.get('/invoices/held');
    return response.list.map(HeldInvoice.fromJson).toList();
  }

  Future<void> discardHeld(String id) => _api.delete('/invoices/held/$id');
}

/// سطر فاتورة زي ما السيرفر بيستقبله — السعر بيتحدد عنده مش هنا.
class InvoiceLineInput {
  const InvoiceLineInput({
    required this.productId,
    required this.quantity,
    this.discountType,
    this.discountValue,
  });

  final String productId;
  final int quantity;
  final String? discountType;
  final double? discountValue;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'product': productId,
        'quantity': quantity,
        if (discountType != null) 'discountType': discountType,
        if (discountValue != null) 'discountValue': discountValue,
      };
}

class PaymentInput {
  const PaymentInput({required this.method, required this.amount});

  final String method;
  final double amount;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'method': method, 'amount': amount};
}

class DiscountInput {
  const DiscountInput({required this.type, required this.value});

  /// 'percentage' أو 'fixed'
  final String type;
  final double value;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'type': type, 'value': value};
}

/// فاتورة اتعتمدت — الأرقام دي جاية من السيرفر.
class CompletedInvoice {
  const CompletedInvoice({
    required this.id,
    required this.number,
    required this.total,
    required this.taxAmount,
    required this.paidAmount,
    required this.changeDue,
    required this.creditAmount,
    required this.itemsCount,
  });

  factory CompletedInvoice.fromJson(Map<String, dynamic> json) {
    final List<dynamic> lines = json['lines'] as List<dynamic>? ?? <dynamic>[];

    return CompletedInvoice(
      id: json['id'] as String,
      number: json['number'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      changeDue: (json['changeDue'] as num?)?.toDouble() ?? 0,
      creditAmount: (json['creditAmount'] as num?)?.toDouble() ?? 0,
      itemsCount: lines.fold<int>(
        0,
        (int sum, dynamic line) =>
            sum + (((line as Map<String, dynamic>)['quantity'] as num?)?.toInt() ?? 0),
      ),
    );
  }

  final String id;
  final String number;
  final double total;
  final double taxAmount;
  final double paidAmount;
  final double changeDue;
  final double creditAmount;
  final int itemsCount;
}
