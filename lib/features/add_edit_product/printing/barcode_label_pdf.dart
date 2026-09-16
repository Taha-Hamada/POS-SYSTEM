import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/printing/pdf_kit.dart';
import '../../../utils/formatters.dart';

/// ملصق باركود 50×30 مم: الاسم والباركود والسعر.
///
/// الباركود بيتطبع EAN-13 لو الرقم صالح (زي اللي بيتولّد من الفورم)،
/// وإلا Code128 اللي بيقبل أي كود.
Future<Uint8List> buildBarcodeLabelPdf({
  required String name,
  required String barcode,
  required double price,
  int copies = 1,
  PdfPageFormat format = PdfKit.labelFormat,
}) async {
  final pw.ThemeData theme = await PdfKit.theme();
  final pw.Barcode ean = pw.Barcode.ean13();
  final pw.Barcode symbology = barcode.length == 13 && ean.isValid(barcode)
      ? ean
      : pw.Barcode.code128();

  final pw.Document doc = pw.Document(title: 'ملصق $name');

  for (int i = 0; i < copies.clamp(1, 500); i += 1) {
    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: format,
          textDirection: pw.TextDirection.rtl,
          theme: theme,
        ),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: <pw.Widget>[
            pw.Text(
              name,
              maxLines: 1,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1),
                child: pw.BarcodeWidget(
                  barcode: symbology,
                  data: barcode,
                  textStyle: const pw.TextStyle(fontSize: 6.5),
                ),
              ),
            ),
            pw.Text(
              Fmt.money(price),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  return doc.save();
}
