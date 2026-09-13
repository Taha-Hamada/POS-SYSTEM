/// فاتورة معلّقة على السيرفر.
///
/// التعليق مبقاش نسخة في ذاكرة الجهاز: السيرفر بيحجز رصيد أصنافها،
/// فالكاشير التاني مايقدرش يبيع كمية محجوزة، والفاتورة بترجع حتى لو
/// الجهاز اتقفل أو الكاشير فتح على جهاز تاني.
class HeldInvoice {
  const HeldInvoice({
    required this.id,
    required this.label,
    required this.itemsCount,
    required this.subtotal,
    required this.total,
    required this.heldAt,
    this.customerName,
    this.lines = const <HeldInvoiceLine>[],
  });

  factory HeldInvoice.fromJson(Map<String, dynamic> json) {
    final dynamic customer = json['customer'];
    final List<dynamic> rawLines = json['lines'] as List<dynamic>? ?? <dynamic>[];

    final List<HeldInvoiceLine> lines = rawLines
        .cast<Map<String, dynamic>>()
        .map(HeldInvoiceLine.fromJson)
        .toList();

    return HeldInvoice(
      id: json['id'] as String,
      label: (json['label'] as String?)?.trim().isNotEmpty == true
          ? json['label'] as String
          : 'فاتورة معلّقة',
      itemsCount: lines.fold<int>(0, (int s, HeldInvoiceLine l) => s + l.quantity),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      heldAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      customerName: customer is Map<String, dynamic>
          ? customer['name'] as String?
          : null,
      lines: lines,
    );
  }

  final String id;
  final String label;
  final int itemsCount;
  final double subtotal;
  final double total;
  final DateTime heldAt;
  final String? customerName;
  final List<HeldInvoiceLine> lines;
}

/// سطر جوه فاتورة معلّقة — الاسم والسعر متخزنين وقت التعليق.
class HeldInvoiceLine {
  const HeldInvoiceLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  factory HeldInvoiceLine.fromJson(Map<String, dynamic> json) {
    final dynamic product = json['product'];

    return HeldInvoiceLine(
      productId: product is Map<String, dynamic>
          ? product['id'] as String
          : product as String,
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;
}
