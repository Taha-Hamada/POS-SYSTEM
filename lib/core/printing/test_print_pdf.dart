import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/store_settings.dart';
import 'pdf_kit.dart';

/// صفحة اختبار الطباعة: بتتأكد إن الطابعة والورق والعربي شغالين.
Future<Uint8List> buildTestPrintPdf({
  required StoreSettings store,
  PdfPageFormat? format,
}) async {
  final pw.ThemeData theme = await PdfKit.theme();
  final PdfPageFormat page = format ?? PdfKit.rollFormat(store.receiptWidthMm);

  final pw.Document doc = pw.Document(title: 'اختبار الطباعة');

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
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'صفحة اختبار الطباعة',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9),
          ),
          PdfKit.divider(),
          PdfKit.kv('عرض الورق', '${store.receiptWidthMm} مم'),
          PdfKit.kv('التاريخ', PdfKit.dateTime(DateTime.now())),
          PdfKit.kv('عيّنة مبلغ', '1,234.50 ${store.currency}'),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: 'TEST-PRINT',
              width: 40 * PdfPageFormat.mm,
              height: 10 * PdfPageFormat.mm,
              drawText: false,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'لو الكلام العربي والباركود ظاهرين صح، الطابعة جاهزة.',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}
