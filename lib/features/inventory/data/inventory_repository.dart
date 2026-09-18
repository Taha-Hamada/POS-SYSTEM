import '../../../core/api/api_client.dart';
import '../../../core/data/branches_repository.dart';
import '../../../core/models/branch.dart';
import '../models/product_branch_stock.dart';
import '../models/stock_record.dart';

/// صفحة من سجلات المخزون مع عددها الكلي.
typedef StockPage = ({List<StockRecord> items, int total});

/// إجماليات مخزون الفرع، محسوبة على السيرفر.
typedef InventorySummary = ({
  int items,
  int units,
  double value,
  double retailValue,
  int outOfStock,
  int lowStock,
  int nearExpiry,
});

/// قراءة وتعديل المخزون من الـ API.
class InventoryRepository {
  const InventoryRepository(this._api);

  final ApiClient _api;

  /// الفلترة والترقيم بيتعملوا على السيرفر، فالعدّاد بيطابق المعروض.
  Future<StockPage> fetchStock({
    required String branchId,
    int page = 1,
    int limit = 50,
    String? status,
    String? categoryId,
    String? search,
    String? sort,
  }) async {
    final ApiResponse response = await _api.get(
      '/inventory/stock',
      query: <String, dynamic>{
        'branch': branchId,
        'page': page,
        'limit': limit,
        'status': status,
        'category': categoryId,
        'search': search,
        'sort': sort,
      },
    );

    return (
      items: response.list.map(StockRecord.fromJson).toList(),
      total: response.total,
    );
  }

  Future<InventorySummary> fetchSummary(String branchId) async {
    final ApiResponse response = await _api.get(
      '/inventory/summary',
      query: <String, dynamic>{'branch': branchId},
    );

    final Map<String, dynamic> data = response.object;

    return (
      items: (data['items'] as num?)?.toInt() ?? 0,
      units: (data['units'] as num?)?.toInt() ?? 0,
      value: (data['value'] as num?)?.toDouble() ?? 0,
      retailValue: (data['retailValue'] as num?)?.toDouble() ?? 0,
      outOfStock: (data['outOfStock'] as num?)?.toInt() ?? 0,
      lowStock: (data['lowStock'] as num?)?.toInt() ?? 0,
      nearExpiry: (data['nearExpiry'] as num?)?.toInt() ?? 0,
    );
  }

  /// الفروع المتاحة للفلتر.
  ///
  /// أمين المخزن مبيشوفش الفروع، فبترجّع فاضية بدل ما ترمي خطأ،
  /// والشاشة بتقفل على فرعه.
  Future<List<Branch>> fetchBranches() => BranchesRepository(_api).fetchAll();

  Future<List<StockMovement>> fetchMovements({
    String? branchId,
    String? productId,
    String? reason,
    int limit = 50,
  }) async {
    final ApiResponse response = await _api.get(
      '/inventory/movements',
      query: <String, dynamic>{
        'branch': branchId,
        'product': productId,
        'reason': reason,
        'limit': limit,
      },
    );

    return response.list.map(StockMovement.fromJson).toList();
  }

  /// رصيد منتج واحد موزّع على الفروع — بتستخدمه شاشة تفاصيل المنتج.
  Future<List<ProductBranchStock>> fetchBranchStock(String productId) async {
    final ApiResponse response = await _api.get('/inventory/product/$productId');

    return response.list.map(ProductBranchStock.fromJson).toList();
  }

  /// تسوية يدوية — [delta] هو الفرق مش الرصيد النهائي.
  Future<void> adjust({
    required String productId,
    required String branchId,
    required double delta,
    String? note,
  }) =>
      _api.post(
        '/inventory/adjust',
        body: <String, dynamic>{
          'product': productId,
          'branch': branchId,
          'quantity': delta,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );

  /// جرد — بنبعت الرصيد المعدود والسيرفر بيحسب الفرق.
  Future<double> stocktake({
    required String productId,
    required String branchId,
    required double countedQuantity,
    String? note,
  }) async {
    final ApiResponse response = await _api.post(
      '/inventory/stocktake',
      body: <String, dynamic>{
        'product': productId,
        'branch': branchId,
        'countedQuantity': countedQuantity,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return (response.object['delta'] as num?)?.toDouble() ?? 0;
  }

  Future<void> transfer({
    required String productId,
    required String fromBranchId,
    required String toBranchId,
    required double quantity,
    String? note,
  }) =>
      _api.post(
        '/inventory/transfer',
        body: <String, dynamic>{
          'product': productId,
          'fromBranch': fromBranchId,
          'toBranch': toBranchId,
          'quantity': quantity,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );

  Future<void> setMinStock({
    required String productId,
    required String branchId,
    required int minStock,
  }) =>
      _api.patch(
        '/inventory/min-stock',
        body: <String, dynamic>{
          'product': productId,
          'branch': branchId,
          'minStock': minStock,
        },
      );
}
