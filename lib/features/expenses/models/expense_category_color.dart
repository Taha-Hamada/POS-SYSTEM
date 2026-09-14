import 'package:flutter/material.dart';

/// لون ثابت لكل بند مصروف.
///
/// البنود نص حر على السيرفر، فمفيش قايمة نقرا منها ترتيب البند؛ اللون بيتحسب
/// من النص نفسه عشان نفس البند يطلع بنفس اللون في كل مكان.
Color expenseCategoryColor(String category) {
  const List<Color> palette = <Color>[
    Color(0xFF6366F1),
    Color(0xFF0EA5E9),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFF64748B),
  ];

  final int hash = category.codeUnits
      .fold<int>(0, (int sum, int unit) => (sum * 31 + unit) & 0x7FFFFFFF);

  return palette[hash % palette.length];
}
