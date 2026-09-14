import '../../../core/api/api_client.dart';
import '../models/returnable_invoice.dart';

/// قراءة وتسجيل المرتجعات من الـ API.
class ReturnsRepository {
  const ReturnsRepository(this._api);

  final ApiClient _api;

  /// بيدوّر على الفاتورة برقمها المطبوع على الإيصال.
  Future<ReturnableInvoice> findByNumber(String number) async {
    final ApiResponse invoice = await _api.get('/invoices/number/$number');
    final String id = invoice.object['id'] as String;

    return fetchReturnable(id);
  }

  /// الأصناف المتاح إرجاعها من فاتورة، بكمياتها المتبقية.
  Future<ReturnableInvoice> fetchReturnable(String invoiceId) async {
    final ApiResponse response = await _api.get('/returns/returnable/$invoiceId');
    return ReturnableInvoice.fromJson(response.object);
  }

  Future<CompletedReturn> submit({
    required String invoiceId,
    required List<ReturnLineInput> lines,
    required String refundMethod,
    String? reason,
    String? note,
  }) async {
    final ApiResponse response = await _api.post(
      '/returns',
      body: <String, dynamic>{
        'invoice': invoiceId,
        'lines': lines.map((ReturnLineInput l) => l.toJson()).toList(),
        'refundMethod': refundMethod,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return CompletedReturn.fromJson(response.object);
  }
}

/// سطر مرتجع بالشكل اللي السيرفر بيستقبله.
class ReturnLineInput {
  const ReturnLineInput({
    required this.invoiceLineId,
    required this.quantity,
    this.restock = true,
    this.reason,
  });

  final String invoiceLineId;
  final int quantity;

  /// الصنف رجع سليم ولا تالف. التالف مبيرجعش للمخزون.
  final bool restock;
  final String? reason;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'invoiceLine': invoiceLineId,
        'quantity': quantity,
        'restock': restock,
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
      };
}
