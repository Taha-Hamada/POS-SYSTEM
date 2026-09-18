import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'category.dart';

/// منتج جاي من الـ API.
///
/// بيقدّم نفس الحقول والخصائص المشتقة اللي الشاشات كانت بتستخدمها من البيانات
/// الوهمية، عشان تحويل أي شاشة يبقى تغيير سطر الاستيراد مش إعادة كتابة الودجتس.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.cost,
    required this.stock,
    required this.minStock,
    required this.unit,
    required this.colorIndex,
    this.barcode,
    this.category,
    this.brand = '',
    this.isActive = true,
    this.trackStock = true,
    this.isTaxable = true,
    this.expiryDate,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // القسم بيرجع ككائن كامل لما الاستعلام يعمل populate، وكمعرّف نص من غيره.
    final dynamic rawCategory = json['category'];

    return Product(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String?,
      category: rawCategory is Map<String, dynamic>
          ? Category.fromJson(rawCategory)
          : null,
      brand: json['brand'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      // الرصيد بيتحسب للفرع المطلوب وبيتلزق جنب المنتج في الرد.
      // الرصيد ممكن يكون بكسور للأصناف اللي بتتباع بالكيلو أو اللتر.
      stock: (json['stock'] as num?)?.toDouble() ?? 0,
      minStock: (json['effectiveMinStock'] ?? json['minStock'] as num?) is num
          ? ((json['effectiveMinStock'] ?? json['minStock']) as num).toInt()
          : 0,
      trackStock: json['trackStock'] as bool? ?? true,
      isTaxable: json['isTaxable'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.tryParse(json['expiryDate'] as String),
      imageUrl: json['imageUrl'] as String?,
      colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
    );
  }

  /// بيستخدم لما رد السيرفر ميكونش شايل كل الحقول، زي تعطيل منتج:
  /// الرد بيرجّع المنتج من غير رصيد الفرع، فبنحتفظ بالرصيد اللي عندنا.
  Product copyWith({bool? isActive, double? stock}) => Product(
        id: id,
        name: name,
        sku: sku,
        barcode: barcode,
        category: category,
        brand: brand,
        unit: unit,
        price: price,
        cost: cost,
        stock: stock ?? this.stock,
        minStock: minStock,
        trackStock: trackStock,
        isTaxable: isTaxable,
        isActive: isActive ?? this.isActive,
        expiryDate: expiryDate,
        imageUrl: imageUrl,
        colorIndex: colorIndex,
      );

  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final Category? category;
  final String brand;
  final String unit;
  final double price;
  final double cost;
  final double stock;
  final int minStock;
  final bool trackStock;
  final bool isTaxable;
  final bool isActive;
  final DateTime? expiryDate;
  final String? imageUrl;
  final int colorIndex;

  Color get accentColor =>
      AppColors.productPalette[colorIndex % AppColors.productPalette.length];

  /// المنتجات الخدمية (زي الأكياس) مالهاش مخزون، فمبتبقاش ناقصة أبدًا.
  bool get isOutOfStock => trackStock && stock <= 0;

  bool get isLowStock => trackStock && stock > 0 && stock <= minStock;

  bool get isNearExpiry {
    final DateTime? date = expiryDate;
    if (date == null) return false;
    return date.difference(DateTime.now()).inDays <= 30;
  }

  double get profitMargin => price <= 0 ? 0 : ((price - cost) / price) * 100;

  String get categoryId => category?.id ?? '';
  String get categoryName => category?.name ?? '—';
  IconData get categoryIcon => category?.icon ?? Icons.inventory_2_outlined;
}
