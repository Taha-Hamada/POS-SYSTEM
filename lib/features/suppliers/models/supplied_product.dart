import 'package:flutter/material.dart';

import '../../../core/models/category.dart';
import '../../../theme/app_theme.dart';

/// صنف وردّه المورد فعلًا، محسوب من أوامر الشراء بتاعته.
///
/// المنتج مش مربوط بمورد على السيرفر عن قصد — نفس الصنف بيتجاب من أكتر من
/// مورد — فالتبويب بيقرا اللي اتطلب منه فعلًا بآخر سعر شراء اتدفع فيه.
class SuppliedProduct {
  const SuppliedProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.cost,
    required this.lastUnitCost,
    required this.stock,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.ordersCount,
    this.unit = '',
    this.category,
    this.colorIndex = 0,
    this.minStock = 0,
    this.trackStock = true,
    this.lastOrderDate,
  });

  factory SuppliedProduct.fromJson(Map<String, dynamic> json) {
    final dynamic category = json['category'];

    return SuppliedProduct(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      category: category is Map<String, dynamic>
          ? Category.fromJson(category)
          : null,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      lastUnitCost: (json['lastUnitCost'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toDouble() ?? 0,
      minStock: (json['minStock'] as num?)?.toInt() ?? 0,
      trackStock: json['trackStock'] as bool? ?? true,
      colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
      orderedQuantity: (json['orderedQuantity'] as num?)?.toDouble() ?? 0,
      receivedQuantity: (json['receivedQuantity'] as num?)?.toDouble() ?? 0,
      ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
      lastOrderDate: DateTime.tryParse(json['lastOrderDate'] as String? ?? ''),
    );
  }

  final String id;
  final String name;
  final String sku;
  final String unit;
  final Category? category;
  final double price;

  /// تكلفة المنتج الحالية — متوسط مرجّح بيحسبه السيرفر مع كل استلام.
  final double cost;

  /// آخر سعر شراء اتدفع للمورد ده في الصنف ده.
  final double lastUnitCost;
  final double stock;
  final int minStock;
  final bool trackStock;
  final int colorIndex;
  final double orderedQuantity;
  final double receivedQuantity;
  final int ordersCount;
  final DateTime? lastOrderDate;

  String get categoryName => category?.name ?? '—';
  IconData get categoryIcon => category?.icon ?? Icons.inventory_2_outlined;

  Color get accentColor =>
      AppColors.productPalette[colorIndex % AppColors.productPalette.length];

  bool get isOutOfStock => trackStock && stock <= 0;
  bool get isLowStock => trackStock && stock > 0 && stock <= minStock;

  /// الهامش محسوب على آخر سعر شراء من المورد ده، مش على متوسط التكلفة.
  double get profitMargin =>
      price <= 0 ? 0 : ((price - lastUnitCost) / price) * 100;
}
