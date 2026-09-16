import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/store_settings.dart';
import '../../../core/printing/pdf_kit.dart';
import '../../../utils/formatters.dart';
import '../../dashboard/models/dashboard_data.dart';
import '../controllers/reports_controller.dart';
import '../models/report_period.dart';
import '../models/report_rows.dart';
import '../models/report_type.dart';

/// التقرير المعروض كجدول واحد — نفس البيانات بتطلع Excel وPDF.
///
/// الخلايا أرقام حقيقية (int/double) مش نصوص، عشان الـExcel يجمع ويفرز.
class ReportTable {
  const ReportTable({
    required this.title,
    required this.subtitle,
    required this.headers,
    required this.rows,
    this.summary = const <(String, String)>[],
    this.numeric = const <int>{},
  });

  final String title;
  final String subtitle;
  final List<String> headers;
  final List<List<Object>> rows;

  /// أرقام إجمالية فوق الجدول: (العنوان، القيمة المنسّقة).
  final List<(String, String)> summary;
  final Set<int> numeric;

  String get fileName =>
      '$title - ${Fmt.date(DateTime.now()).replaceAll('/', '-')}';
}

ReportTable reportTableOf(ReportsController r) {
  final String branch = r.branchId == null
      ? 'كل الفروع'
      : r.branches
                .where((BranchStats b) => b.id == r.branchId)
                .map((BranchStats b) => b.name)
                .firstOrNull ??
            'فرع محدد';
  final String subtitle = '${r.period.label} | $branch';

  return switch (r.type) {
    ReportType.sales => ReportTable(
      title: r.type.label,
      subtitle: subtitle,
      headers: const <String>[
        'التاريخ',
        'الفواتير',
        'المبيعات',
        'الضريبة',
        'الربح',
      ],
      numeric: const <int>{1, 2, 3, 4},
      summary: <(String, String)>[
        ('إجمالي المبيعات', Fmt.money(r.totalSales)),
        ('عدد الفواتير', Fmt.count(r.totalInvoices)),
        ('متوسط الفاتورة', Fmt.money(r.avgInvoice)),
        ('متوسط اليوم', Fmt.money(r.avgDay)),
      ],
      rows: <List<Object>>[
        for (final SalesPoint p in r.series)
          <Object>[Fmt.date(p.date), p.invoices, p.sales, p.tax, p.profit],
      ],
    ),
    ReportType.profit => ReportTable(
      title: r.type.label,
      subtitle: subtitle,
      headers: const <String>[
        'القسم',
        'الوحدات',
        'الإيراد',
        'التكلفة',
        'الربح',
        'الهامش %',
        'النصيب %',
      ],
      numeric: const <int>{1, 2, 3, 4, 5, 6},
      summary: <(String, String)>[
        ('إجمالي المبيعات', Fmt.money(r.totalSales)),
        ('إجمالي الربح', Fmt.money(r.totalProfit)),
      ],
      rows: <List<Object>>[
        for (final CategoryReportRow c in r.categoryRows)
          <Object>[
            c.name,
            c.units,
            c.revenue,
            c.cost,
            c.profit,
            _round(c.margin),
            _round(c.share),
          ],
      ],
    ),
    ReportType.products => ReportTable(
      title: r.type.label,
      subtitle: subtitle,
      headers: const <String>['المنتج', 'SKU', 'الوحدات', 'الإيراد', 'الربح'],
      numeric: const <int>{2, 3, 4},
      rows: <List<Object>>[
        for (final TopProduct p in r.topProducts)
          <Object>[p.name, p.sku, p.units, p.revenue, p.profit],
      ],
    ),
    ReportType.employees => ReportTable(
      title: r.type.label,
      subtitle: subtitle,
      headers: const <String>[
        'الموظف',
        'اسم المستخدم',
        'الفواتير',
        'المبيعات',
        'الخصومات',
        'متوسط الفاتورة',
      ],
      numeric: const <int>{2, 3, 4, 5},
      rows: <List<Object>>[
        for (final EmployeeReportRow e in r.employeeRows)
          <Object>[
            e.name,
            e.username,
            e.invoices,
            e.sales,
            e.discounts,
            e.averageTicket,
          ],
      ],
    ),
    ReportType.taxes => ReportTable(
      title: r.type.label,
      subtitle: subtitle,
      headers: const <String>[
        'الشهر',
        'المبيعات قبل الضريبة',
        'الضريبة',
        'الفواتير',
      ],
      numeric: const <int>{1, 2, 3},
      summary: <(String, String)>[
        ('الضريبة المحصّلة', Fmt.money(r.taxCollected)),
        ('الضريبة المدفوعة', Fmt.money(r.taxPaid)),
        ('الصافي المستحق', Fmt.money(r.taxNet)),
      ],
      rows: <List<Object>>[
        for (final MonthlyTaxRow m in r.monthlyTaxRows)
          <Object>[m.label, m.taxableBase, m.tax, m.invoices],
      ],
    ),
    ReportType.inventory => ReportTable(
      title: r.type.label,
      subtitle: subtitle,
      headers: const <String>[
        'القسم',
        'الأصناف',
        'الوحدات',
        'التكلفة',
        'قيمة البيع',
        'الربح المتوقع',
      ],
      numeric: const <int>{1, 2, 3, 4, 5},
      summary: <(String, String)>[
        ('إجمالي التكلفة', Fmt.money(r.inventoryTotalCost)),
        ('إجمالي قيمة البيع', Fmt.money(r.inventoryTotalRetail)),
      ],
      rows: <List<Object>>[
        for (final InventoryReportRow i in r.inventoryRows)
          <Object>[
            i.name,
            i.items,
            i.units,
            i.cost,
            i.retail,
            i.expectedProfit,
          ],
      ],
    ),
  };
}

double _round(double value) => (value * 10).roundToDouble() / 10;

String _format(Object value) => switch (value) {
  int() => Fmt.count(value),
  double() => Fmt.amount(value),
  _ => value.toString(),
};

/// ملف xlsx بورقة واحدة من اليمين للشمال.
Uint8List buildReportExcel(ReportTable table) {
  final Excel excel = Excel.createExcel();
  const String sheetName = 'التقرير';
  excel.rename('Sheet1', sheetName);

  final Sheet sheet = excel[sheetName];
  sheet.isRTL = true;

  final CellStyle bold = CellStyle(bold: true);
  final CellStyle header = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#E2E8F0'),
  );

  void styleRow(int rowIndex, int columns, CellStyle style) {
    for (int c = 0; c < columns; c += 1) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex),
              )
              .cellStyle =
          style;
    }
  }

  sheet.appendRow(<CellValue?>[TextCellValue(table.title)]);
  styleRow(0, 1, bold);
  sheet.appendRow(<CellValue?>[TextCellValue(table.subtitle)]);

  if (table.summary.isNotEmpty) {
    sheet.appendRow(<CellValue?>[]);
    for (final (String label, String value) in table.summary) {
      sheet.appendRow(<CellValue?>[TextCellValue(label), TextCellValue(value)]);
    }
  }

  sheet.appendRow(<CellValue?>[]);
  sheet.appendRow(<CellValue?>[
    for (final String h in table.headers) TextCellValue(h),
  ]);
  styleRow(sheet.maxRows - 1, table.headers.length, header);

  for (final List<Object> row in table.rows) {
    sheet.appendRow(<CellValue?>[
      for (final Object value in row)
        switch (value) {
          int() => IntCellValue(value),
          double() => DoubleCellValue(value),
          _ => TextCellValue(value.toString()),
        },
    ]);
  }

  for (int c = 0; c < table.headers.length; c += 1) {
    sheet.setColumnWidth(c, c == 0 ? 26 : 18);
  }

  // مكتبة excel بتكتب اتجاه اليمين للشمال للأوراق اللي ليها ملف جوه الـxlsx
  // بس، والورقة اللي اتعملت rename لسه مالهاش لحد أول حفظ. فبنحفظ مرة،
  // ونفتح الملف ونثبّت الاتجاه، ونحفظ تاني.
  final Excel reopened = Excel.decodeBytes(excel.encode()!);
  reopened[sheetName].isRTL = true;

  return Uint8List.fromList(reopened.encode()!);
}

/// نفس الجدول كـPDF A4.
Future<Uint8List> buildReportPdf(ReportTable table, StoreSettings store) async {
  final pw.Document doc = await PdfKit.a4Document(
    title: table.title,
    subtitle: table.subtitle,
    store: store,
    body: () => <pw.Widget>[
      if (table.summary.isNotEmpty) ...<pw.Widget>[
        for (final (String label, String value) in table.summary)
          PdfKit.kv(label, value, bold: true, size: 10),
        pw.SizedBox(height: 8),
      ],
      if (table.rows.isEmpty)
        pw.Text(
          'مفيش بيانات في الفترة دي',
          style: const pw.TextStyle(fontSize: 10),
        )
      else
        PdfKit.table(
          headers: table.headers,
          numeric: table.numeric,
          flex: const <int, double>{0: 1.8},
          rows: <List<String>>[
            for (final List<Object> row in table.rows)
              <String>[for (final Object v in row) _format(v)],
          ],
        ),
    ],
  );

  return doc.save();
}
