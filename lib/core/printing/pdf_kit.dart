import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../utils/formatters.dart';
import '../models/store_settings.dart';

/// أدوات مشتركة لكل ملفات الـPDF: الخط العربي والجدول وسطور القيم.
class PdfKit {
  const PdfKit._();

  static pw.ThemeData? _theme;

  /// الخط العربي مدمج في التطبيق، والـHelvetica احتياطي للحروف اللاتينية.
  static Future<pw.ThemeData> theme() async {
    if (_theme != null) return _theme!;

    final pw.Font regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'),
    );
    final pw.Font bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf'),
    );

    return _theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: <pw.Font>[pw.Font.helvetica()],
    );
  }

  /// التاريخ والوقت من غير الشرطة الطويلة اللي في [Fmt.dateTime] —
  /// الخطوط المدمجة مفيهاش الحرف ده فبيتطبع مربع.
  static String dateTime(DateTime value) =>
      '${Fmt.date(value)}  ${Fmt.time(value)}';

  /// صفحة رول (إيصال) بعرض الورق من الإعدادات وطول مفتوح.
  static PdfPageFormat rollFormat(int widthMm) => PdfPageFormat(
    (widthMm <= 58 ? 58 : 80) * PdfPageFormat.mm,
    double.infinity,
    marginAll: 3 * PdfPageFormat.mm,
  );

  /// ملصق باركود 50×30 مم.
  static const PdfPageFormat labelFormat = PdfPageFormat(
    50 * PdfPageFormat.mm,
    30 * PdfPageFormat.mm,
    marginAll: 1.5 * PdfPageFormat.mm,
  );

  static pw.Widget divider() => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Divider(
      height: 1,
      thickness: 0.6,
      color: PdfColors.grey600,
      borderStyle: pw.BorderStyle.dashed,
    ),
  );

  /// سطر «عنوان ..... قيمة».
  static pw.Widget kv(
    String label,
    String value, {
    bool bold = false,
    double size = 9,
    PdfColor? color,
  }) {
    final pw.TextStyle style = pw.TextStyle(
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.2),
      child: pw.Row(
        children: <pw.Widget>[
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.SizedBox(width: 6),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static pw.Widget sectionTitle(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
    child: pw.Text(
      title,
      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    ),
  );

  /// جدول عربي: أول عمود على اليمين.
  ///
  /// ‏[pw.Table] بيرسم الأعمدة من الشمال لليمين دايمًا، فبنعكس ترتيبها.
  /// الأعمدة اللي في [numeric] بتتصف على الشمال زي الأرقام في الشاشات.
  static pw.Widget table({
    required List<String> headers,
    required List<List<String>> rows,
    Set<int> numeric = const <int>{},
    Map<int, double> flex = const <int, double>{},
    double fontSize = 8.5,
  }) {
    final int count = headers.length;

    pw.Widget cell(String text, int column, {bool header = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: pw.Text(
            text,
            textAlign: numeric.contains(column)
                ? pw.TextAlign.left
                : pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: header ? fontSize + 0.5 : fontSize,
              fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );

    List<pw.Widget> reversed(List<String> values, {bool header = false}) =>
        <pw.Widget>[
          for (int c = count - 1; c >= 0; c -= 1)
            cell(c < values.length ? values[c] : '', c, header: header),
        ];

    return pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: PdfColors.grey500, width: 0.6),
        bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.6),
        horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.4),
      ),
      columnWidths: <int, pw.TableColumnWidth>{
        for (int i = 0; i < count; i += 1)
          i: pw.FlexColumnWidth(flex[count - 1 - i] ?? 1),
      },
      children: <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: reversed(headers, header: true),
        ),
        for (final List<String> row in rows)
          pw.TableRow(children: reversed(row)),
      ],
    );
  }

  /// رأس مستندات A4: اسم المتجر وبياناته على اليمين والعنوان تحته.
  static pw.Widget documentHeader({
    required StoreSettings store,
    required String title,
    String subtitle = '',
  }) {
    final String contact = <String>[
      store.storeAddress,
      store.storePhone,
      if (store.taxNumber.isNotEmpty) 'رقم ضريبي ${store.taxNumber}',
    ].where((String s) => s.isNotEmpty).join(' | ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          store.storeName,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        if (contact.isNotEmpty)
          pw.Text(
            contact,
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
        pw.SizedBox(height: 10),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        if (subtitle.isNotEmpty)
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.8, color: PdfColors.grey500),
      ],
    );
  }

  /// تذييل مستندات A4: وقت الطباعة ورقم الصفحة.
  static pw.Widget documentFooter(pw.Context context) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    child: pw.Row(
      children: <pw.Widget>[
        pw.Expanded(
          child: pw.Text(
            'اتطبع ${dateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        pw.Text(
          'صفحة ${context.pageNumber} من ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    ),
  );

  /// صفحات A4 عربية بالرأس والتذييل الموحّدين.
  static Future<pw.Document> a4Document({
    required String title,
    required StoreSettings store,
    String subtitle = '',
    required List<pw.Widget> Function() body,
  }) async {
    final pw.ThemeData theme = await PdfKit.theme();
    final pw.Document doc = pw.Document(title: title, author: store.storeName);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          textDirection: pw.TextDirection.rtl,
          theme: theme,
        ),
        header: (pw.Context context) => context.pageNumber == 1
            ? documentHeader(store: store, title: title, subtitle: subtitle)
            : pw.SizedBox(),
        footer: documentFooter,
        build: (_) => body(),
      ),
    );

    return doc;
  }
}
