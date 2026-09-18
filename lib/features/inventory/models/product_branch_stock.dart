/// رصيد منتج واحد في فرع واحد — بيتجاب من `/inventory/product/:id`.
///
/// الفرع اللي المنتج معدّاش عليه أصلًا مالوش سجل على السيرفر، فمبيرجعش هنا.
class ProductBranchStock {
  const ProductBranchStock({
    required this.branchId,
    required this.branchName,
    required this.quantity,
    required this.minStock,
    this.lastCountedAt,
    this.updatedAt,
  });

  factory ProductBranchStock.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> branch =
        (json['branch'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return ProductBranchStock(
      branchId: branch['_id'] as String? ?? branch['id'] as String? ?? '',
      branchName: branch['name'] as String? ?? '—',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      // حد الطلب الفعلي محسوب على السيرفر: تجاوز الفرع أو حد المنتج.
      minStock: (json['effectiveMinStock'] as num?)?.toInt() ?? 0,
      lastCountedAt: DateTime.tryParse(json['lastCountedAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  final String branchId;
  final String branchName;
  final double quantity;
  final int minStock;
  final DateTime? lastCountedAt;
  final DateTime? updatedAt;

  bool get isOut => quantity <= 0;
  bool get isLow => quantity > 0 && quantity <= minStock;
}
