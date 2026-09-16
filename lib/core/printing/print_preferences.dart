import 'package:shared_preferences/shared_preferences.dart';

/// تفضيلات الطباعة الخاصة بالجهاز ده.
///
/// الطابعة متوصلة بجهاز الكاشير، فالإعداد بيتحفظ عليه مش على السيرفر:
/// جهاز عليه طابعة إيصالات وجهاز مدير من غيرها.
class PrintPreferences {
  const PrintPreferences._();

  static const String _autoPrintKey = 'print.auto_receipt';
  static const String _printerUrlKey = 'print.receipt_printer_url';
  static const String _printerNameKey = 'print.receipt_printer_name';

  /// طباعة الإيصال تلقائيًا بعد كل بيعة — مقفولة لحد ما حد يفعّلها.
  static Future<bool> autoPrintReceipt() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoPrintKey) ?? false;
  }

  static Future<void> setAutoPrintReceipt(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPrintKey, value);
  }

  /// الطابعة اللي الإيصالات بتروح لها على طول، أو null لفتح حوار الطباعة.
  static Future<({String url, String name})?> receiptPrinter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? url = prefs.getString(_printerUrlKey);
    if (url == null || url.isEmpty) return null;

    return (url: url, name: prefs.getString(_printerNameKey) ?? url);
  }

  /// [url] فاضي معناه رجوع لحوار الطباعة العادي.
  static Future<void> setReceiptPrinter({String? url, String? name}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (url == null || url.isEmpty) {
      await prefs.remove(_printerUrlKey);
      await prefs.remove(_printerNameKey);
      return;
    }

    await prefs.setString(_printerUrlKey, url);
    await prefs.setString(_printerNameKey, name ?? url);
  }
}
