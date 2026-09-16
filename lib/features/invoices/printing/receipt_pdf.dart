import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/store_settings.dart';
import '../../../core/printing/pdf_kit.dart';
import '../../../utils/formatters.dart';
import '../models/invoice_record.dart';

/// إيصال البيع على ورق الرول (58 أو 80 مم).
Future<Uint8List> buildReceiptPdf({
  required InvoiceRecord invoice,
  required StoreSettings store,
  PdfPageFormat? format,
}) async {
  final pw.ThemeData theme = await PdfKit.theme();
  final PdfPageFormat page = format ?? PdfKit.rollFormat(store.receiptWidthMm);
  final bool narrow = page.width < 70 * PdfPageFormat.mm;
  final double size = narrow ? 7.5 : 8.5;

  final pw.Document doc = pw.Document(title: 'إيصال ${invoice.number}');

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
              fontSize: narrow ? 11 : 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          for (final String line in <String>[
            store.storeAddress,
            store.storePhone,
            if (store.taxNumber.isNotEmpty) 'رقم ضريبي ${store.taxNumber}',
          ])
            if (line.isNotEmpty)
              pw.Text(
                line,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: size - 0.5),
              ),
          PdfKit.divider(),
          PdfKit.kv('فاتورة', invoice.number, bold: true, size: size),
          PdfKit.kv('التاريخ', PdfKit.dateTime(invoice.createdAt), size: size),
          if (invoice.cashierName.isNotEmpty)
            PdfKit.kv('الكاشير', invoice.cashierName, size: size),
          if (invoice.customerName != null)
            PdfKit.kv('العميل', invoice.customerName!, size: size),
          if (invoice.isVoided)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                'فاتورة ملغاة',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: size + 1,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          PdfKit.divider(),
          for (final InvoiceRecordLine line in invoice.lines) ...<pw.Widget>[
            pw.Text(
              line.name,
              style: pw.TextStyle(
                fontSize: size,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            PdfKit.kv(
              '${Fmt.trimDecimals(line.quantity)} × ${Fmt.amount(line.unitPrice)}',
              Fmt.amount(line.lineTotal),
              size: size,
            ),
            if (line.promotionName.isNotEmpty)
              pw.Text(
                line.promotionName,
                style: pw.TextStyle(
                  fontSize: size - 1,
                  color: PdfColors.grey700,
                ),
              ),
            pw.SizedBox(height: 2),
          ],
          PdfKit.divider(),
          PdfKit.kv(
            'الإجمالي قبل الخصم',
            Fmt.amount(invoice.subtotal),
            size: size,
          ),
          if (invoice.discountTotal > 0)
            PdfKit.kv(
              'الخصومات',
              '-${Fmt.amount(invoice.discountTotal)}',
              size: size,
            ),
          PdfKit.kv('الضريبة', Fmt.amount(invoice.taxAmount), size: size),
          PdfKit.kv(
            'الإجمالي',
            Fmt.money(invoice.total),
            bold: true,
            size: size + 2,
          ),
          PdfKit.divider(),
          for (final InvoicePayment p in invoice.payments)
            PdfKit.kv(p.methodLabel, Fmt.amount(p.amount), size: size),
          if (invoice.changeDue > 0)
            PdfKit.kv('الباقي', Fmt.amount(invoice.changeDue), size: size),
          if (invoice.creditAmount > 0)
            PdfKit.kv(
              'على الحساب',
              Fmt.amount(invoice.creditAmount),
              size: size,
            ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: invoice.number,
              drawText: false,
              width: narrow ? 40 * PdfPageFormat.mm : 55 * PdfPageFormat.mm,
              height: 10 * PdfPageFormat.mm,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            store.receiptFooter.isEmpty
                ? 'شكرًا لزيارتكم'
                : store.receiptFooter,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: size),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}
