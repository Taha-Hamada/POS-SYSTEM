import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

/// صنف رصيده وصل لحد إعادة الطلب أو خلص في فرع.
class LowStockAlert {
  const LowStockAlert({
    required this.productId,
    required this.name,
    required this.sku,
    required this.branchName,
    required this.quantity,
    required this.minStock,
    this.unit = '',
    this.branchId,
  });

  factory LowStockAlert.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> product =
        json['product'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, dynamic> branch =
        json['branch'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return LowStockAlert(
      productId: product['id'] as String? ?? '',
      name: product['name'] as String? ?? '',
      sku: product['sku'] as String? ?? '',
      unit: product['unit'] as String? ?? '',
      branchId: branch['id'] as String?,
      branchName: branch['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      minStock: (json['effectiveMinStock'] as num?)?.toDouble() ?? 0,
    );
  }

  final String productId;
  final String name;
  final String sku;
  final String unit;
  final String? branchId;
  final String branchName;
  final double quantity;

  /// حد إعادة الطلب الفعلي — حد الفرع لو متحدد، وإلا حد المنتج.
  final double minStock;

  bool get isOut => quantity <= 0;
}

/// منتج صلاحيته قربت تخلص أو خلصت.
class ExpiringProduct {
  const ExpiringProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.expiryDate,
    this.unit = '',
  });

  factory ExpiringProduct.fromJson(Map<String, dynamic> json) =>
      ExpiringProduct(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        expiryDate:
            DateTime.tryParse(json['expiryDate'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );

  final String id;
  final String name;
  final String sku;
  final String unit;
  final DateTime expiryDate;

  /// الأيام الباقية من النهاردة — بالسالب لو خلصت.
  int get daysLeft {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    return day.difference(today).inDays;
  }

  bool get isExpired => daysLeft < 0;
}

/// تنبيهات المخزون: النواقص وقرب انتهاء الصلاحية.
class StockAlertsRepository {
  const StockAlertsRepository(this._api);

  final ApiClient _api;

  /// من غير فرع السيرفر بيرجّع نواقص كل الفروع (لمدير النظام).
  Future<List<LowStockAlert>> fetchLowStock({
    String? branchId,
    int limit = 200,
  }) async {
    try {
      final ApiResponse response = await _api.get(
        '/inventory/low-stock',
        query: <String, dynamic>{'branch': branchId, 'limit': limit},
      );
      return response.list.map(LowStockAlert.fromJson).toList();
    } on ApiException catch (exception) {
      if (exception.isForbidden) return <LowStockAlert>[];
      rethrow;
    }
  }

  /// المنتجات اللي صلاحيتها بتخلص خلال [days] يوم، ومعاها اللي خلصت فعلًا.
  Future<List<ExpiringProduct>> fetchExpiring({int days = 30}) async {
    try {
      final ApiResponse response = await _api.get(
        '/products/expiring',
        query: <String, dynamic>{'days': days},
      );
      return response.list.map(ExpiringProduct.fromJson).toList();
    } on ApiException catch (exception) {
      if (exception.isForbidden) return <ExpiringProduct>[];
      rethrow;
    }
  }
}
