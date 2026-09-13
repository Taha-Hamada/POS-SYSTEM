/// نوع الخصم: مبلغ ثابت بالجنيه، أو نسبة من المجموع الفرعي.
enum DiscountType { amount, percent }

extension DiscountTypeInfo on DiscountType {
  String get label => switch (this) {
        DiscountType.amount => 'مبلغ',
        DiscountType.percent => 'نسبة',
      };

  /// اللاحقة اللي بتظهر في خانة الإدخال.
  String get suffix => switch (this) {
        DiscountType.amount => 'ج.م',
        DiscountType.percent => '%',
      };

  /// القيم السريعة تحت الخانة — بالجنيه أو بالنسبة حسب النوع.
  List<double> get presets => switch (this) {
        DiscountType.amount => <double>[10, 20, 50, 100],
        DiscountType.percent => <double>[5, 10, 15, 20],
      };
}

/// خصم الفاتورة — بيتخزّن كنوع + قيمة عشان الفاتورة تعرف تكتب
/// «خصم 40 ج.م» ولا «خصم 10%».
class CartDiscount {
  const CartDiscount({required this.type, required this.value});

  const CartDiscount.none()
      : type = DiscountType.amount,
        value = 0;

  final DiscountType type;
  final double value;

  bool get isEmpty => value <= 0;

  bool get isPercentage => type == DiscountType.percent;

  /// القيمة بالجنيه بعد تطبيقها على [subtotal].
  double amountFor(double subtotal) => switch (type) {
        DiscountType.amount => value,
        DiscountType.percent => subtotal * value / 100,
      };

  /// نص مختصر للعرض جنب كلمة «الخصم» في ملخّص الفاتورة.
  String get shortLabel {
    if (type == DiscountType.amount) return '';
    final String number = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return ' ($number%)';
  }
}
