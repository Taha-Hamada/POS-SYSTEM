import '../widgets/status_badge.dart';

/// حالة أمر الشراء على السيرفر.
enum PurchaseOrderStatus {
  draft,
  confirmed,
  partiallyReceived,
  completed,
  cancelled,
}

extension PurchaseOrderStatusInfo on PurchaseOrderStatus {
  String get apiValue => switch (this) {
        PurchaseOrderStatus.draft => 'draft',
        PurchaseOrderStatus.confirmed => 'confirmed',
        PurchaseOrderStatus.partiallyReceived => 'partially_received',
        PurchaseOrderStatus.completed => 'completed',
        PurchaseOrderStatus.cancelled => 'cancelled',
      };

  String get label => switch (this) {
        PurchaseOrderStatus.draft => 'مسودة',
        PurchaseOrderStatus.confirmed => 'مؤكد',
        PurchaseOrderStatus.partiallyReceived => 'مستلم جزئيًا',
        PurchaseOrderStatus.completed => 'مكتمل',
        PurchaseOrderStatus.cancelled => 'ملغي',
      };

  /// رمادي = مسودة، أزرق = مؤكد، برتقالي = مستلم جزئيًا،
  /// أخضر = مكتمل، أحمر = ملغي.
  StatusTone get tone => switch (this) {
        PurchaseOrderStatus.draft => StatusTone.neutral,
        PurchaseOrderStatus.confirmed => StatusTone.info,
        PurchaseOrderStatus.partiallyReceived => StatusTone.warning,
        PurchaseOrderStatus.completed => StatusTone.success,
        PurchaseOrderStatus.cancelled => StatusTone.danger,
      };
}

PurchaseOrderStatus purchaseOrderStatusFromApi(String? value) =>
    PurchaseOrderStatus.values
        .where((PurchaseOrderStatus s) => s.apiValue == value)
        .firstOrNull ??
    PurchaseOrderStatus.draft;

String _lineProductId(dynamic value) => value is Map<String, dynamic>
    ? value['id'] as String? ?? ''
    : value as String? ?? '';

/// سطر في أمر شراء.
class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.id,
    required this.productId,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.receivedQuantity,
    required this.unitCost,
    required this.lineTotal,
  });

  factory PurchaseOrderLine.fromJson(Map<String, dynamic> json) =>
      PurchaseOrderLine(
        id: json['id'] as String? ?? json['_id'] as String? ?? '',
        productId: _lineProductId(json['product']),
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        receivedQuantity: (json['receivedQuantity'] as num?)?.toDouble() ?? 0,
        unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
        lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      );

  /// معرّف السطر نفسه — هو اللي مسار الاستلام بيتعامل بيه مش معرّف المنتج.
  final String id;
  final String productId;
  final String name;
  final String sku;
  final double quantity;
  final double receivedQuantity;
  final double unitCost;
  final double lineTotal;

  double get remaining {
    final double left = quantity - receivedQuantity;
    return left < 0 ? 0 : left;
  }

  bool get isFullyReceived => remaining <= 0;

  double get receivedRatio =>
      quantity <= 0 ? 0 : (receivedQuantity / quantity).clamp(0, 1);
}

/// أمر شراء جاي من الـ API.
///
/// قايمة الأوامر بترجع من غير السطور (`select: '-lines'`)، فـ[lines] بتبقى
/// فاضية لحد ما الأمر يتقرا لوحده.
class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.number,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.orderDate,
    required this.subtotal,
    required this.shippingCost,
    required this.total,
    this.expectedDate,
    this.supplierPhone = '',
    this.supplierContact = '',
    this.branchId = '',
    this.branchName = '',
    this.lines = const <PurchaseOrderLine>[],
    this.receivedValue = 0,
    this.note = '',
    this.createdBy = '',
    this.cancelReason = '',
    this.totalQuantity = 0,
    this.receivedQuantity = 0,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    final dynamic supplier = json['supplier'];
    final dynamic branch = json['branch'];
    final dynamic createdBy = json['createdBy'];

    final List<PurchaseOrderLine> lines =
        (json['lines'] as List<dynamic>? ?? <dynamic>[])
            .cast<Map<String, dynamic>>()
            .map(PurchaseOrderLine.fromJson)
            .toList(growable: false);

    return PurchaseOrder(
      id: json['id'] as String? ?? '',
      number: json['number'] as String? ?? '',
      supplierId: _idOf(supplier),
      supplierName: _fieldOf(supplier, 'name'),
      supplierPhone: _fieldOf(supplier, 'phone'),
      supplierContact: _fieldOf(supplier, 'contactPerson'),
      branchId: _idOf(branch),
      branchName: _fieldOf(branch, 'name'),
      status: purchaseOrderStatusFromApi(json['status'] as String?),
      orderDate:
          DateTime.tryParse(json['orderDate'] as String? ?? '') ?? DateTime.now(),
      expectedDate: DateTime.tryParse(json['expectedDate'] as String? ?? ''),
      lines: lines,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      receivedValue: (json['receivedValue'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String? ?? '',
      createdBy: _fieldOf(createdBy, 'name'),
      cancelReason: json['cancelReason'] as String? ?? '',
      // السيرفر بيحسب الإجماليات دي كـvirtuals، فبنفضّلها على جمع السطور
      // اللي ممكن تكون مش مرجّعة أصلًا في القايمة.
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0,
      receivedQuantity: (json['receivedQuantity'] as num?)?.toDouble() ?? 0,
    );
  }

  static String _idOf(dynamic value) => value is Map<String, dynamic>
      ? value['id'] as String? ?? ''
      : value as String? ?? '';

  static String _fieldOf(dynamic value, String field) =>
      value is Map<String, dynamic> ? value[field] as String? ?? '' : '';

  final String id;
  final String number;
  final String supplierId;
  final String supplierName;
  final String supplierPhone;
  final String supplierContact;
  final String branchId;
  final String branchName;
  final PurchaseOrderStatus status;
  final DateTime orderDate;
  final DateTime? expectedDate;
  final List<PurchaseOrderLine> lines;
  final double subtotal;
  final double shippingCost;
  final double total;

  /// القيمة المستلمة فعلًا — هي اللي اتحمّلت على حساب المورد.
  final double receivedValue;
  final String note;
  final String createdBy;
  final String cancelReason;
  final double totalQuantity;
  final double receivedQuantity;

  bool get isDraft => status == PurchaseOrderStatus.draft;
  bool get isCancelled => status == PurchaseOrderStatus.cancelled;
  bool get isCompleted => status == PurchaseOrderStatus.completed;

  /// الاستلام متاح للمؤكد والمستلم جزئيًا بس.
  bool get canReceive =>
      status == PurchaseOrderStatus.confirmed ||
      status == PurchaseOrderStatus.partiallyReceived;

  /// الإلغاء بيقفل لو دخل منه حاجة المخزن.
  bool get canCancel => !isCompleted && !isCancelled && receivedQuantity <= 0;

  double get receivedRatio =>
      totalQuantity <= 0 ? 0 : (receivedQuantity / totalQuantity).clamp(0, 1);

  int get linesCount => lines.length;
}
