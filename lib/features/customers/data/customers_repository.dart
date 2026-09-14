import '../../../core/api/api_client.dart';
import '../../../core/models/customer.dart';
import '../models/customer_entries.dart';

/// إجماليات مديونية العملاء.
typedef Receivables = ({double total, int count});

/// قراءة وتعديل العملاء من الـ API.
class CustomersRepository {
  const CustomersRepository(this._api);

  final ApiClient _api;

  static const int _pageSize = 100;

  /// بيجيب كل العملاء صفحة ورا صفحة.
  ///
  /// الشاشة بتفلتر وترتّب محليًا، والبطاقات محتاجة الإجماليات على الكل،
  /// فمحتاجة القايمة كاملة.
  Future<List<Customer>> fetchAll() async {
    final List<Customer> customers = <Customer>[];
    int page = 1;

    while (true) {
      final ApiResponse response = await _api.get(
        '/customers',
        query: <String, dynamic>{'page': page, 'limit': _pageSize},
      );

      customers.addAll(response.list.map(Customer.fromJson));

      if (!response.hasNext) break;
      page += 1;
    }

    return customers;
  }

  Future<Customer> fetchById(String id) async {
    final ApiResponse response = await _api.get('/customers/$id');
    return Customer.fromJson(response.object);
  }

  Future<Receivables> fetchReceivables() async {
    final ApiResponse response = await _api.get('/customers/receivables');

    return (
      total: (response.object['total'] as num?)?.toDouble() ?? 0,
      count: (response.object['count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<LedgerEntry>> fetchLedger(String id) async {
    final ApiResponse response = await _api.get(
      '/customers/$id/ledger',
      query: <String, dynamic>{'limit': 50},
    );

    return response.list.map(LedgerEntry.fromJson).toList();
  }

  Future<List<LoyaltyEntry>> fetchLoyalty(String id) async {
    final ApiResponse response = await _api.get(
      '/customers/$id/loyalty',
      query: <String, dynamic>{'limit': 50},
    );

    return response.list.map(LoyaltyEntry.fromJson).toList();
  }

  /// فواتير العميل — بتتقرا من مسار الفواتير مش من العميل.
  Future<List<CustomerInvoice>> fetchInvoices(String id) async {
    final ApiResponse response = await _api.get(
      '/invoices',
      query: <String, dynamic>{'customer': id, 'limit': 50},
    );

    return response.list.map(CustomerInvoice.fromJson).toList();
  }

  Future<Customer> create({
    required String name,
    required String phone,
    String? email,
    double? creditLimit,
  }) async {
    final ApiResponse response = await _api.post(
      '/customers',
      body: <String, dynamic>{
        'name': name,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'creditLimit': ?creditLimit,
      },
    );

    return Customer.fromJson(response.object);
  }

  Future<Customer> update(String id, Map<String, dynamic> changes) async {
    final ApiResponse response = await _api.patch('/customers/$id', body: changes);
    return Customer.fromJson(response.object);
  }

  Future<Customer> setActive(String id, {required bool isActive}) async {
    final ApiResponse response = await _api.patch(
      '/customers/$id/active',
      body: <String, bool>{'isActive': isActive},
    );

    return Customer.fromJson(response.object);
  }

  /// سداد من العميل — بيرفع رصيده ناحية الصفر.
  Future<Customer> recordPayment(
    String id, {
    required double amount,
    String? note,
  }) async {
    final ApiResponse response = await _api.post(
      '/customers/$id/payments',
      body: <String, dynamic>{
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return Customer.fromJson(
      (response.object['customer'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
    );
  }

  /// استبدال نقط بخصم — بيرجّع العميل بعد الخصم وقيمة الاستبدال.
  Future<({Customer customer, double valueAmount})> redeemPoints(
    String id, {
    required int points,
  }) async {
    final ApiResponse response = await _api.post(
      '/customers/$id/loyalty/redeem',
      body: <String, int>{'points': points},
    );

    return (
      customer: Customer.fromJson(
        (response.object['customer'] as Map<String, dynamic>?) ??
            <String, dynamic>{},
      ),
      valueAmount: (response.object['valueAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
