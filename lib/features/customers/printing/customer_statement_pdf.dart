import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/customer.dart';
import '../../../core/models/store_settings.dart';
import '../../../core/printing/pdf_kit.dart';
import '../../../utils/formatters.dart';
import '../models/customer_entries.dart';

/// كشف حساب العميل A4: بياناته ورصيده وحركات حسابه وفواتيره.
Future<Uint8List> buildCustomerStatementPdf({
  required Customer customer,
  required List<LedgerEntry> ledger,
  required List<CustomerInvoice> invoices,
  required StoreSettings store,
}) async {
  String statusLabel(CustomerInvoice i) => switch (i.status) {
    'completed' => 'مكتملة',
    'partially_returned' => 'مرتجع جزئي',
    'returned' => 'مرتجعة',
    'voided' => 'ملغاة',
    _ => i.status,
  };

  final pw.Document doc = await PdfKit.a4Document(
    title: 'كشف حساب ${customer.name}',
    subtitle: 'حتى ${PdfKit.dateTime(DateTime.now())}',
    store: store,
    body: () => <pw.Widget>[
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Column(
                children: <pw.Widget>[
                  PdfKit.kv('العميل', customer.name, bold: true),
                  PdfKit.kv('الموبايل', customer.phone),
                ],
              ),
            ),
            pw.SizedBox(width: 24),
            pw.Expanded(
              child: pw.Column(
                children: <pw.Widget>[
                  PdfKit.kv(
                    customer.hasDebt ? 'المديونية' : 'الرصيد',
                    Fmt.money(
                      customer.hasDebt ? customer.debt : customer.balance,
                    ),
                    bold: true,
                    color: customer.hasDebt ? PdfColors.red800 : null,
                  ),
                  PdfKit.kv('حد الائتمان', Fmt.money(customer.creditLimit)),
                  PdfKit.kv(
                    'إجمالي المشتريات',
                    Fmt.money(customer.totalPurchases),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      PdfKit.sectionTitle('حركات الحساب'),
      if (ledger.isEmpty)
        pw.Text('مفيش حركات على الحساب', style: const pw.TextStyle(fontSize: 9))
      else
        PdfKit.table(
          headers: <String>[
            'التاريخ',
            'الحركة',
            'البيان',
            'المبلغ',
            'الرصيد بعدها',
          ],
          flex: const <int, double>{0: 1.3, 1: 1, 2: 2.6, 3: 1.2, 4: 1.3},
          numeric: const <int>{3, 4},
          rows: <List<String>>[
            for (final LedgerEntry e in ledger)
              <String>[
                Fmt.date(e.createdAt),
                e.typeLabel,
                e.note.isEmpty ? (e.branchName ?? '') : e.note,
                Fmt.amount(e.amount),
                Fmt.amount(e.balanceAfter),
              ],
          ],
        ),
      PdfKit.sectionTitle('الفواتير'),
      if (invoices.isEmpty)
        pw.Text('مفيش فواتير', style: const pw.TextStyle(fontSize: 9))
      else
        PdfKit.table(
          headers: <String>['رقم الفاتورة', 'التاريخ', 'الحالة', 'الإجمالي'],
          numeric: const <int>{3},
          rows: <List<String>>[
            for (final CustomerInvoice i in invoices)
              <String>[
                i.number,
                PdfKit.dateTime(i.createdAt),
                statusLabel(i),
                Fmt.amount(i.total),
              ],
          ],
        ),
    ],
  );

  return doc.save();
}
