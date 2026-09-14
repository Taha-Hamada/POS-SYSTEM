import 'package:flutter/material.dart';

import '../../../core/models/material_icon_names.dart';

/// سطور التقارير زي ما الـ API بيرجّعها.
///
/// كل سطر بيحمل أرقامه جاهزة محسوبة على السيرفر، فالشاشة بتعرض بس.
double _num(dynamic value) => (value as num?)?.toDouble() ?? 0;
int _int(dynamic value) => (value as num?)?.toInt() ?? 0;

/// لون القسم الجاي من الـ API بصيغة ‎#RRGGBB.
Color _color(dynamic value) {
  final String? hex = value as String?;
  if (hex == null || hex.length != 7) return const Color(0xFF6366F1);

  final int? parsed = int.tryParse(hex.substring(1), radix: 16);
  return parsed == null ? const Color(0xFF6366F1) : Color(0xFF000000 | parsed);
}

/// سطر مجمّع حسب الفئة (بيُستخدم في تقرير الأرباح).
class CategoryReportRow {
  const CategoryReportRow({
    required this.categoryId,
    required this.name,
    required this.iconName,
    required this.color,
    required this.units,
    required this.revenue,
    required this.profit,
    required this.share,
  });

  factory CategoryReportRow.fromJson(Map<String, dynamic> json) =>
      CategoryReportRow(
        categoryId: json['category'] as String? ?? '',
        name: json['name'] as String? ?? '',
        iconName: json['icon'] as String? ?? 'category',
        color: _color(json['color']),
        units: _num(json['units']),
        revenue: _num(json['revenue']),
        profit: _num(json['profit']),
        share: _num(json['share']),
      );

  final String categoryId;
  final String name;
  final String iconName;
  final Color color;
  final double units;
  final double revenue;
  final double profit;

  /// نصيب القسم من إجمالي المبيعات، بالنسبة المئوية.
  final double share;

  IconData get icon => iconForName(iconName);

  double get cost => revenue - profit;
  double get margin => revenue == 0 ? 0 : (profit / revenue) * 100;
}

/// سطر أداء كاشير خلال الفترة.
class EmployeeReportRow {
  const EmployeeReportRow({
    required this.id,
    required this.name,
    required this.username,
    required this.sales,
    required this.invoices,
    required this.discounts,
    required this.averageTicket,
  });

  factory EmployeeReportRow.fromJson(Map<String, dynamic> json) =>
      EmployeeReportRow(
        id: json['cashier'] as String? ?? '',
        name: json['name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        sales: _num(json['sales']),
        invoices: _int(json['invoices']),
        discounts: _num(json['discounts']),
        averageTicket: _num(json['averageTicket']),
      );

  final String id;
  final String name;
  final String username;
  final double sales;
  final int invoices;
  final double discounts;
  final double averageTicket;

  String get initials {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}';
  }
}

/// سطر قيمة المخزون لفئة واحدة.
class InventoryReportRow {
  const InventoryReportRow({
    required this.categoryId,
    required this.name,
    required this.iconName,
    required this.color,
    required this.items,
    required this.units,
    required this.cost,
    required this.retail,
  });

  factory InventoryReportRow.fromJson(Map<String, dynamic> json) =>
      InventoryReportRow(
        categoryId: json['category'] as String? ?? '',
        name: json['name'] as String? ?? '',
        iconName: json['icon'] as String? ?? 'category',
        color: _color(json['color']),
        items: _int(json['items']),
        units: _num(json['units']),
        cost: _num(json['cost']),
        retail: _num(json['retail']),
      );

  final String categoryId;
  final String name;
  final String iconName;
  final Color color;
  final int items;
  final double units;
  final double cost;
  final double retail;

  IconData get icon => iconForName(iconName);

  double get expectedProfit => retail - cost;
}

/// سطر شهري في الإقرار الضريبي.
class MonthlyTaxRow {
  const MonthlyTaxRow({
    required this.key,
    required this.taxableBase,
    required this.tax,
    required this.invoices,
  });

  factory MonthlyTaxRow.fromJson(Map<String, dynamic> json) => MonthlyTaxRow(
        key: json['month'] as String? ?? '',
        taxableBase: _num(json['taxableBase']),
        tax: _num(json['tax']),
        invoices: _int(json['invoices']),
      );

  /// المفتاح بصيغة `YYYY-MM` زي ما السيرفر بيرجّعه.
  final String key;

  /// المبيعات قبل الضريبة.
  final double taxableBase;
  final double tax;
  final int invoices;

  double get sales => taxableBase;

  bool get isCurrentMonth {
    final DateTime now = DateTime.now();
    return key == '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String get label {
    const List<String> names = <String>[
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    final List<String> parts = key.split('-');
    if (parts.length < 2) return key;

    final int month = int.tryParse(parts[1]) ?? 1;
    return '${names[(month - 1).clamp(0, 11)]} ${parts[0]}';
  }
}

/// الإقرار الضريبي كامل.
///
/// اسمه Summary مش Report عشان ميتلخبطش مع الودجت اللي بتعرضه.
class TaxSummary {
  const TaxSummary({
    this.taxRate = 0,
    this.collected = 0,
    this.paid = 0,
    this.net = 0,
    this.months = const <MonthlyTaxRow>[],
  });

  factory TaxSummary.fromJson(Map<String, dynamic> json) => TaxSummary(
        taxRate: _num(json['taxRate']),
        collected: _num(json['collected']),
        paid: _num(json['paid']),
        net: _num(json['net']),
        months: (json['months'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(MonthlyTaxRow.fromJson)
            .toList()
            .reversed
            .toList(),
      );

  final double taxRate;

  /// الضريبة المحصّلة من المبيعات.
  final double collected;

  /// الضريبة المدفوعة في المشتريات المستلمة.
  final double paid;

  /// الفرق — ده اللي بيتورّد للمصلحة.
  final double net;

  final List<MonthlyTaxRow> months;
}
