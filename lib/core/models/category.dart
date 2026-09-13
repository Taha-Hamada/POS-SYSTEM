import 'package:flutter/material.dart';

import 'material_icon_names.dart';

/// قسم منتجات جاي من الـ API.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
    this.parentId,
    this.productsCount = 0,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final dynamic parent = json['parent'];

    return Category(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      iconName: json['icon'] as String? ?? 'category',
      color: _parseHex(json['color'] as String?),
      parentId: parent is Map<String, dynamic>
          ? parent['id'] as String?
          : parent as String?,
      productsCount: (json['productsCount'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final String iconName;
  final Color color;
  final String? parentId;
  final int productsCount;
  final bool isActive;

  IconData get icon => iconForName(iconName);

  bool get isRoot => parentId == null;

  /// الباك اند بيبعت اللون بصيغة #RRGGBB.
  static Color _parseHex(String? value) {
    if (value == null || value.length != 7) return const Color(0xFF6366F1);

    final int? parsed = int.tryParse(value.substring(1), radix: 16);
    return parsed == null ? const Color(0xFF6366F1) : Color(0xFF000000 | parsed);
  }
}
