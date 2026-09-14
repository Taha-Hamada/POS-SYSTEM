import 'package:flutter/material.dart';

import '../../../core/models/material_icon_names.dart';

/// رصيد منتج في فرع، زي ما السيرفر بيرجّعه.
class StockRecord {
  const StockRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unit,
    required this.cost,
    required this.price,
    required this.onHand,
    required this.reserved,
    required this.minStock,
    required this.lastMovement,
    this.categoryName = '—',
    this.categoryIconName = 'category',
    this.branchId,
    this.branchName = '',
  });

  factory StockRecord.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> product =
        (json['product'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic>? category =
        product['category'] as Map<String, dynamic>?;
    final dynamic branch = json['branch'];

    return StockRecord(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      productId: product['_id'] as String? ?? product['id'] as String? ?? '',
      productName: product['name'] as String? ?? '',
      sku: product['sku'] as String? ?? '',
      unit: product['unit'] as String? ?? '',
      cost: (product['cost'] as num?)?.toDouble() ?? 0,
      price: (product['price'] as num?)?.toDouble() ?? 0,
      onHand: (json['quantity'] as num?)?.toInt() ?? 0,
      reserved: (json['reserved'] as num?)?.toInt() ?? 0,
      // حد الطلب الفعلي محسوب على السيرفر: تجاوز الفرع أو حد المنتج.
      minStock: (json['effectiveMinStock'] as num?)?.toInt() ?? 0,
      lastMovement: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      categoryName: category?['name'] as String? ?? '—',
      categoryIconName: category?['icon'] as String? ?? 'category',
      branchId: branch is Map<String, dynamic>
          ? branch['id'] as String?
          : branch as String?,
      branchName:
          branch is Map<String, dynamic> ? branch['name'] as String? ?? '' : '',
    );
  }

  final String id;
  final String productId;
  final String productName;
  final String sku;
  final String unit;
  final double cost;
  final double price;

  /// الكمية الفعلية على الرف.
  final int onHand;

  /// كمية محجوزة لفواتير معلّقة.
  final int reserved;

  final int minStock;
  final DateTime lastMovement;
  final String categoryName;
  final String categoryIconName;
  final String? branchId;
  final String branchName;

  IconData get categoryIcon => iconForName(categoryIconName);

  /// المتاح للبيع فعليًا.
  int get available => (onHand - reserved).clamp(0, onHand);

  double get value => cost * onHand;

  bool get isOut => onHand <= 0;
  bool get isLow => onHand > 0 && onHand <= minStock;
}

/// حركة مخزون في السجل.
class StockMovement {
  const StockMovement({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.balanceAfter,
    required this.reason,
    required this.createdAt,
    this.note = '',
    this.branchName = '',
    this.performedBy,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    final dynamic product = json['product'];
    final dynamic branch = json['branch'];
    final dynamic user = json['performedBy'];

    return StockMovement(
      id: json['id'] as String? ?? '',
      productName: product is Map<String, dynamic>
          ? product['name'] as String? ?? ''
          : '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String? ?? '',
      branchName:
          branch is Map<String, dynamic> ? branch['name'] as String? ?? '' : '',
      performedBy: user is Map<String, dynamic> ? user['name'] as String? : null,
    );
  }

  final String id;
  final String productName;

  /// موجب = دخول للمخزن، سالب = خروج منه.
  final int quantity;
  final int balanceAfter;
  final String reason;
  final DateTime createdAt;
  final String note;
  final String branchName;
  final String? performedBy;

  bool get isIncoming => quantity > 0;

  String get reasonLabel => switch (reason) {
        'sale' => 'بيع',
        'return' => 'مرتجع',
        'purchase' => 'شراء',
        'adjustment' => 'تسوية',
        'transfer_in' => 'تحويل وارد',
        'transfer_out' => 'تحويل صادر',
        'stocktake' => 'جرد',
        'damage' => 'تالف',
        'opening' => 'رصيد افتتاحي',
        _ => reason,
      };
}
