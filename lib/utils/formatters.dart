import 'package:intl/intl.dart';

/// تنسيق موحّد للأرقام والمبالغ والتواريخ في كل الشاشات.
///
/// بنستخدم الأرقام اللاتينية (1234) مش الهندية (١٢٣٤) لأنها أوضح وأسرع
/// في القراءة على شاشات نقاط البيع.
class Fmt {
  const Fmt._();

  static const String currencySymbol = 'ج.م';

  static final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _moneyCompactInt = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _int = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _qty = NumberFormat('#,##0.###', 'en_US');
  static final NumberFormat _percent = NumberFormat('#,##0.0', 'en_US');
  static final DateFormat _date = DateFormat('yyyy/MM/dd', 'en_US');
  static final DateFormat _time = DateFormat('hh:mm a', 'en_US');

  /// 1,234.50 ج.م
  static String money(num value) => '${_money.format(value)} $currencySymbol';

  /// 1,234.50 — من غير رمز العملة
  static String amount(num value) => _money.format(value);

  /// 1,235 ج.م — للمبالغ الكبيرة في البطاقات الإحصائية
  static String moneyRounded(num value) =>
      '${_moneyCompactInt.format(value)} $currencySymbol';

  /// 1.2 ألف / 1.5 مليون
  static String compact(num value) {
    if (value.abs() >= 1000000) {
      return '${_percent.format(value / 1000000)} مليون';
    }
    if (value.abs() >= 1000) {
      return '${_percent.format(value / 1000)} ألف';
    }
    return _int.format(value);
  }

  static String count(num value) => _int.format(value);

  /// كمية ممكن تكون بكسور: 3 و1.5 و0.25 — من غير أصفار زايدة.
  static String qty(num value) {
    if (value == value.roundToDouble()) return _int.format(value);
    return _qty.format(value);
  }

  /// +12.4% أو -3.1%
  static String changePercent(double value) {
    final String sign = value >= 0 ? '+' : '−';
    return '$sign${_percent.format(value.abs())}%';
  }

  static String percent(double value) => '${_percent.format(value)}%';

  /// 40 بدل 40.00 و12.5 بدل 12.50 — للأرقام اللي بيكتبها المستخدم.
  static String trimDecimals(num value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  static String date(DateTime value) => _date.format(value);

  static String time(DateTime value) => _time.format(value);

  static String dateTime(DateTime value) => '${date(value)} — ${time(value)}';
}
