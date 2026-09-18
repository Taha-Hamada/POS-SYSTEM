import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/shift.dart';
import '../../../core/models/store_settings.dart';
import '../../../core/printing/pdf_kit.dart';
import '../../../utils/formatters.dart';

/// تقرير الوردية على ورق الرول — بيتطبع قبل الإغلاق أو بعده.
///
/// [countedCash] المعدود فعلًا لو الكاشير كتبه؛ من غيره التقرير بيعرض
/// المتوقع بس.
Future<Uint8List> buildShiftReportPdf({
  required Shift shift,
  required ShiftTotals totals,
  required StoreSettings store,
  double? countedCash,
  PdfPageFormat? format,
}) async {
  final pw.ThemeData theme = await PdfKit.theme();
  final PdfPageFormat page = format ?? PdfKit.rollFormat(store.receiptWidthMm);
  final double size = page.width < 70 * PdfPageFormat.mm ? 7.5 : 8.5;

  // بعد الإغلاق الأرقام المتجمّدة هي المرجع.
  final ShiftClosing? closing = shift.closing;
  final double expected = closing?.expectedCash ?? totals.expectedCash;
  final double? counted = closing?.countedCash ?? countedCash;
  final double? difference = counted == null ? null : counted - expected;

  pw.Widget kv(String label, double value, {bool bold = false}) =>
      PdfKit.kv(label, Fmt.amount(value), bold: bold, size: size);

  final pw.Document doc = pw.Document(title: 'تقرير وردية ${shift.number}');

  doc.addPage(
    pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: page,
        textDirection: pw.TextDirection.rtl,
        theme: theme,
      ),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          pw.Text(
            store.storeName,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: size + 3,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'تقرير الوردية',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: size + 1.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          PdfKit.divider(),
          PdfKit.kv('الوردية', shift.number, bold: true, size: size),
          if (shift.cashierName != null)
            PdfKit.kv('الكاشير', shift.cashierName!, size: size),
          if (shift.branchName != null)
            PdfKit.kv('الفرع', shift.branchName!, size: size),
          PdfKit.kv('الفتح', PdfKit.dateTime(shift.openedAt), size: size),
          PdfKit.kv(
            'القفل',
            shift.closedAt == null
                ? 'لسه مفتوحة'
                : PdfKit.dateTime(shift.closedAt!),
            size: size,
          ),
          PdfKit.divider(),
          pw.Text(
            'المبيعات',
            style: pw.TextStyle(
              fontSize: size + 1,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          kv('إجمالي المبيعات', totals.salesTotal, bold: true),
          PdfKit.kv(
            'عدد الفواتير',
            Fmt.count(totals.invoicesCount),
            size: size,
          ),
          kv('كاش', totals.cashSales),
          kv('آجل', totals.creditSales),
          if (totals.discountTotal > 0) kv('الخصومات', totals.discountTotal),
          if (totals.taxTotal > 0) kv('الضريبة', totals.taxTotal),
          if (totals.returnsTotal > 0) kv('المرتجعات', totals.returnsTotal),
          PdfKit.divider(),
          pw.Text(
            'الدرج',
            style: pw.TextStyle(
              fontSize: size + 1,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          kv('الرصيد الافتتاحي', shift.openingBalance),
          kv('مبيعات كاش', totals.cashSales),
          if (totals.cashRefunds > 0) kv('مرتجعات كاش', -totals.cashRefunds),
          if (totals.cashExpenses > 0) kv('مصروفات كاش', -totals.cashExpenses),
          if (totals.cashIn > 0) kv('إيداعات', totals.cashIn),
          if (totals.cashOut > 0) kv('مسحوبات', -totals.cashOut),
          kv('المتوقع في الدرج', expected, bold: true),
          if (counted != null) kv('المعدود فعلًا', counted, bold: true),
          if (difference != null)
            PdfKit.kv(
              difference.abs() < 0.005
                  ? 'الدرج مظبوط'
                  : difference < 0
                  ? 'عجز'
                  : 'زيادة',
              Fmt.amount(difference.abs()),
              bold: true,
              size: size + 1,
            ),
          if ((closing?.note ?? '').isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 3),
            pw.Text(
              'ملاحظة: ${closing!.note}',
              style: pw.TextStyle(fontSize: size),
            ),
          ],
          PdfKit.divider(),
          pw.Text(
            'اتطبع ${PdfKit.dateTime(DateTime.now())}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: size - 1, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),
          PdfKit.kv('توقيع الكاشير', '................', size: size),
          pw.SizedBox(height: 8),
          PdfKit.kv('توقيع المدير', '................', size: size),
        ],
      ),
    ),
  );

  return doc.save();
}
