import 'package:flutter/material.dart';

import '../../../core/models/shift.dart';
import '../../../core/widgets/numpad.dart';
import '../../../theme/app_theme.dart';
import '../models/shift_diff_style.dart';
import '../models/shift_stat.dart';

/// حالة حوارات الوردية: الرصيد الافتتاحي عند الفتح، والعدّ الفعلي عند الإغلاق.
///
/// الأرقام بتيجي محسوبة من السيرفر، فالكنترولر ده مسؤول عن إدخال الكاشير بس.
class ShiftController extends ChangeNotifier {
  ShiftController({
    this.openingBalance = 0,
    this.shift,
    ShiftTotals? totals,
  }) : totals = totals ?? const ShiftTotals();

  /// الرصيد الافتتاحي للوردية المفتوحة.
  final double openingBalance;

  /// الوردية اللي بيتقفل عليها — null في حوار الفتح.
  final Shift? shift;

  /// أرقام الوردية زي ما السيرفر حسبها.
  final ShiftTotals totals;

  /// مبالغ افتتاحية شائعة للاختيار السريع
  static const List<double> presets = <double>[500, 1000, 2000, 5000];

  /// الرصيد الافتتاحي اللي بيتكتب على الـNumpad
  final AmountEntry _entry = AmountEntry(initial: 2000);

  /// العدّ الفعلي اللي دخّله الكاشير
  final TextEditingController countController = TextEditingController();

  // ── بدء الوردية ──────────────────────────────────────────────────────────
  String get openingText => _entry.isEmpty ? '0' : _entry.text;

  double get openingValue => _entry.value;

  bool get isOpeningValid => _entry.value > 0;

  bool isPresetSelected(double value) => _entry.value == value;

  void tapKey(String key) {
    _entry.tapKey(key);
    notifyListeners();
  }

  void backspace() {
    _entry.backspace();
    notifyListeners();
  }

  void setOpening(double value) {
    _entry.setValue(value);
    notifyListeners();
  }

  // ── إغلاق الوردية ────────────────────────────────────────────────────────
  double get opening => openingBalance;

  /// المفروض يكون في الدرج — محسوب على السيرفر عشان يحسب المرتجعات
  /// والمصروفات الكاش كمان، مش المبيعات بس.
  double get expected => totals.expectedCash;

  double? get actual {
    final String text = countController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  bool get isCounted => actual != null;

  double get difference => (actual ?? expected) - expected;

  ShiftDiffStyle get diffStyle =>
      ShiftDiffStyle.of(isCounted: isCounted, difference: difference);

  List<ShiftStat> get stats => <ShiftStat>[
        ShiftStat(
          label: 'إجمالي المبيعات',
          value: totals.salesTotal,
          icon: Icons.receipt_long_rounded,
          color: AppColors.accent,
        ),
        ShiftStat(
          label: 'كاش',
          value: totals.cashSales,
          icon: Icons.payments_rounded,
          color: AppColors.success,
        ),
        ShiftStat(
          label: 'بطاقة',
          value: totals.cardSales,
          icon: Icons.credit_card_rounded,
          color: AppColors.info,
        ),
        ShiftStat(
          label: 'Cash In',
          value: totals.cashIn,
          icon: Icons.arrow_downward_rounded,
          color: AppColors.success,
        ),
        ShiftStat(
          label: 'Cash Out',
          value: totals.cashOut,
          icon: Icons.arrow_upward_rounded,
          color: AppColors.danger,
        ),
      ];

  /// بيتنده مع كل تعديل في خانة العدّ الفعلي.
  void countChanged([String? _]) => notifyListeners();

  @override
  void dispose() {
    countController.dispose();
    super.dispose();
  }
}
