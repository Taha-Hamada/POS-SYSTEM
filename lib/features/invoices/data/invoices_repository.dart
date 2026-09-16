import '../../../core/api/api_client.dart';
import '../models/invoice_record.dart';

typedef InvoicesPage = ({List<InvoiceRecord> items, int total});

typedef InvoicesSummary = ({
  int count,
  double total,
  double returned,
  double profit,
});

/// قراءة سجل الفواتير وإلغاء الفاتورة.
class InvoicesRepository {
  const InvoicesRepository(this._api);

  final ApiClient _api;

  Future<InvoicesPage> fetchPage({
    DateTime? from,
    String? status,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    final ApiResponse response = await _api.get(
      '/invoices',
      query: <String, dynamic>{
        'page': page,
        'limit': limit,
        'from': from?.toUtc().toIso8601String(),
        'status': status,
        'search': search,
      },
    );

    return (
      items: response.list.map(InvoiceRecord.fromJson).toList(),
      total: response.total,
    );
  }

  /// إجماليات الفترة — السيرفر بيستبعد الملغاة منها.
  Future<InvoicesSummary> fetchSummary({DateTime? from}) async {
    final ApiResponse response = await _api.get(
      '/invoices/summary',
      query: <String, dynamic>{'from': from?.toUtc().toIso8601String()},
    );

    double numOf(String key) => (response.object[key] as num?)?.toDouble() ?? 0;

    return (
      count: (response.object['invoicesCount'] as num?)?.toInt() ?? 0,
      total: numOf('total'),
      returned: numOf('returnedTotal'),
      profit: numOf('profit'),
    );
  }

  /// الفاتورة بسطورها ومدفوعاتها.
  Future<InvoiceRecord> fetchOne(String id) async {
    final ApiResponse response = await _api.get('/invoices/$id');
    return InvoiceRecord.fromJson(response.object);
  }

  /// بيلغي الفاتورة: السيرفر بيرجّع المخزون ويعكس حساب العميل.
  Future<InvoiceRecord> voidInvoice(String id, {required String reason}) async {
    final ApiResponse response = await _api.post(
      '/invoices/$id/void',
      body: <String, dynamic>{'reason': reason},
    );

    return InvoiceRecord.fromJson(response.object);
  }
}
