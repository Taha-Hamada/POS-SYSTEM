import '../../../core/api/api_client.dart';
import '../../../core/models/purchase_order.dart';

/// صفحة من أوامر الشراء مع عددها الكلي على السيرفر.
typedef PurchaseOrdersPage = ({List<PurchaseOrder> items, int total});

/// سطر رايح للسيرفر في إنشاء أمر أو تعديله.
typedef PurchaseLineInput = ({
  String productId,
  double quantity,
  double? unitCost,
});

/// سطر استلام — بيتعامل بمعرّف سطر الأمر مش بمعرّف المنتج.
typedef ReceiptLineInput = ({
  String orderLineId,
  double quantity,
  double? unitCost,
});

/// قراءة وكتابة أوامر الشراء من الـ API.
class PurchasesRepository {
  const PurchasesRepository(this._api);

  final ApiClient _api;

  /// القايمة بترجع من غير سطور الأوامر عشان تخف، فـ[PurchaseOrder.lines]
  /// بتبقى فاضية هنا. استخدم [fetchOne] لما تحتاج السطور.
  Future<PurchaseOrdersPage> fetchPage({
    int page = 1,
    int limit = 100,
    String? search,
    String? supplierId,
    String? branchId,
    PurchaseOrderStatus? status,
    DateTime? from,
    DateTime? to,
    String sort = '-orderDate',
  }) async {
    final ApiResponse response = await _api.get(
      '/purchase-orders',
      query: <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort': sort,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'supplier': ?supplierId,
        'branch': ?branchId,
        'status': ?status?.apiValue,
        'from': ?from?.toIso8601String(),
        'to': ?to?.toIso8601String(),
      },
    );

    return (
      items: response.list.map(PurchaseOrder.fromJson).toList(),
      total: response.total,
    );
  }

  Future<PurchaseOrder> fetchOne(String id) async {
    final ApiResponse response = await _api.get('/purchase-orders/$id');
    return PurchaseOrder.fromJson(response.object);
  }

  Future<PurchaseOrder> create({
    required String supplierId,
    required List<PurchaseLineInput> lines,
    String? branchId,
    DateTime? expectedDate,
    double shippingCost = 0,
    String? note,
  }) async {
    final ApiResponse response = await _api.post(
      '/purchase-orders',
      body: <String, dynamic>{
        'supplier': supplierId,
        'branch': ?branchId,
        'lines': lines.map(_lineJson).toList(growable: false),
        'expectedDate': ?expectedDate?.toIso8601String(),
        'shippingCost': shippingCost,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return PurchaseOrder.fromJson(response.object);
  }

  /// التعديل متاح للمسودة بس — السيرفر بيقفله بعد التأكيد.
  Future<PurchaseOrder> update(
    String id, {
    List<PurchaseLineInput>? lines,
    DateTime? expectedDate,
    double? shippingCost,
    String? note,
  }) async {
    final ApiResponse response = await _api.patch(
      '/purchase-orders/$id',
      body: <String, dynamic>{
        if (lines != null)
          'lines': lines.map(_lineJson).toList(growable: false),
        if (expectedDate != null) 'expectedDate': expectedDate.toIso8601String(),
        'shippingCost': ?shippingCost,
        'note': ?note,
      },
    );

    return PurchaseOrder.fromJson(response.object);
  }

  Future<PurchaseOrder> confirm(String id) async {
    final ApiResponse response = await _api.post('/purchase-orders/$id/confirm');
    return PurchaseOrder.fromJson(response.object);
  }

  Future<PurchaseOrder> cancel(String id, {required String reason}) async {
    final ApiResponse response = await _api.post(
      '/purchase-orders/$id/cancel',
      body: <String, String>{'reason': reason},
    );

    return PurchaseOrder.fromJson(response.object);
  }

  /// استلام بضاعة: بيزوّد المخزون ويحمّل القيمة على حساب المورد.
  ///
  /// [updateCost] بيخلي السيرفر يحدّث تكلفة المنتج بالمتوسط المرجح.
  Future<PurchaseOrder> receive(
    String id, {
    required List<ReceiptLineInput> lines,
    bool updateCost = true,
  }) async {
    final ApiResponse response = await _api.post(
      '/purchase-orders/$id/receive',
      body: <String, dynamic>{
        'updateCost': updateCost,
        'lines': <Map<String, dynamic>>[
          for (final ReceiptLineInput line in lines)
            <String, dynamic>{
              'orderLine': line.orderLineId,
              'quantity': line.quantity,
              'unitCost': ?line.unitCost,
            },
        ],
      },
    );

    return PurchaseOrder.fromJson(response.object);
  }

  static Map<String, dynamic> _lineJson(PurchaseLineInput line) =>
      <String, dynamic>{
        'product': line.productId,
        'quantity': line.quantity,
        'unitCost': ?line.unitCost,
      };
}
