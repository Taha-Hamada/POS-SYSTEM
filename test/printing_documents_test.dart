import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pos_system/core/models/customer.dart';
import 'package:pos_system/core/models/shift.dart';
import 'package:pos_system/core/models/store_settings.dart';
import 'package:pos_system/core/printing/pdf_kit.dart';
import 'package:pos_system/core/printing/print_job.dart';
import 'package:pos_system/core/printing/print_preferences.dart';
import 'package:pos_system/features/add_edit_product/printing/barcode_label_pdf.dart';
import 'package:pos_system/features/cashier_shift/printing/shift_report_pdf.dart';
import 'package:pos_system/features/customers/models/customer_entries.dart';
import 'package:pos_system/features/customers/printing/customer_statement_pdf.dart';
import 'package:pos_system/features/invoices/models/invoice_record.dart';
import 'package:pos_system/features/invoices/printing/receipt_pdf.dart';
import 'package:pos_system/features/reports/export/report_export.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// بناء كل المستندات المطبوعة والمصدّرة بالخط العربي المدمج.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const StoreSettings store = StoreSettings(
    storeName: 'متجر الاختبار',
    storeAddress: 'القاهرة',
    storePhone: '0100000000',
    taxNumber: '123-456',
    receiptFooter: 'الاسترجاع خلال 14 يوم',
  );

  bool isPdf(Uint8List bytes) =>
      bytes.length > 1000 && ascii.decode(bytes.sublist(0, 5)) == '%PDF-';

  final InvoiceRecord invoice = InvoiceRecord.fromJson(<String, dynamic>{
    'id': 'inv-1',
    'number': 'INV-000123',
    'status': 'completed',
    'subtotal': 200,
    'lineDiscountTotal': 10,
    'invoiceDiscount': 0,
    'taxAmount': 26.6,
    'total': 216.6,
    'paidAmount': 250,
    'changeDue': 33.4,
    'createdAt': '2026-09-15T10:00:00.000Z',
    'cashier': <String, dynamic>{'name': 'كاشير'},
    'customer': <String, dynamic>{'name': 'أحمد'},
    'payments': <Map<String, dynamic>>[
      <String, dynamic>{'method': 'cash', 'amount': 250},
    ],
    'lines': <Map<String, dynamic>>[
      <String, dynamic>{
        'name': 'بيبسي كانز',
        'quantity': 4,
        'unitPrice': 50,
        'lineTotal': 190,
        'promotionName': 'خصم 5%',
      },
    ],
  });

  test('إيصال البيع بيطلع PDF على رول 80 و58', () async {
    expect(
      isPdf(await buildReceiptPdf(invoice: invoice, store: store)),
      isTrue,
    );

    final Uint8List narrow = await buildReceiptPdf(
      invoice: invoice,
      store: store,
      format: PdfKit.rollFormat(58),
    );
    expect(isPdf(narrow), isTrue);
  });

  test('مقاس الرول بيتبع عرض الورق من الإعدادات', () {
    expect(PdfKit.rollFormat(58).width, closeTo(58 * PdfPageFormat.mm, 0.01));
    expect(PdfKit.rollFormat(80).width, closeTo(80 * PdfPageFormat.mm, 0.01));
    expect(PdfKit.rollFormat(72).width, closeTo(80 * PdfPageFormat.mm, 0.01));
  });

  test('تقرير الوردية قبل الإغلاق وبعده', () async {
    final Shift open = Shift.fromJson(<String, dynamic>{
      'id': 'sh-1',
      'number': 'SH-00001',
      'status': 'open',
      'openingBalance': 500,
      'openedAt': '2026-09-15T08:00:00.000Z',
      'cashier': <String, dynamic>{'name': 'كاشير'},
      'branch': <String, dynamic>{'id': 'b1', 'name': 'الفرع الرئيسي'},
    });
    const ShiftTotals totals = ShiftTotals(
      salesTotal: 2400,
      invoicesCount: 12,
      cashSales: 1900,
      expectedCash: 2400,
      byMethod: <String, double>{'card': 500},
    );

    expect(
      isPdf(
        await buildShiftReportPdf(
          shift: open,
          totals: totals,
          store: store,
          countedCash: 2350,
        ),
      ),
      isTrue,
    );

    final Shift closed = Shift.fromJson(<String, dynamic>{
      'id': 'sh-1',
      'number': 'SH-00001',
      'status': 'closed',
      'openingBalance': 500,
      'openedAt': '2026-09-15T08:00:00.000Z',
      'closedAt': '2026-09-15T16:00:00.000Z',
      'closing': <String, dynamic>{
        'countedCash': 2350,
        'expectedCash': 2400,
        'difference': -50,
        'salesTotal': 2400,
        'invoicesCount': 12,
        'note': 'فكة ناقصة',
      },
    });
    expect(
      isPdf(
        await buildShiftReportPdf(shift: closed, totals: totals, store: store),
      ),
      isTrue,
    );
  });

  test('كشف حساب العميل بالحركات والفواتير', () async {
    final Customer customer = Customer.fromJson(<String, dynamic>{
      'id': 'cu-1',
      'name': 'أحمد علي',
      'phone': '01011111111',
      'balance': -350,
      'creditLimit': 1000,
    });

    final Uint8List bytes = await buildCustomerStatementPdf(
      customer: customer,
      store: store,
      ledger: <LedgerEntry>[
        for (int i = 0; i < 60; i += 1)
          LedgerEntry(
            id: 'l$i',
            type: i.isEven ? 'sale' : 'payment',
            amount: i.isEven ? -100 : 50,
            balanceAfter: -50.0 * i,
            createdAt: DateTime(2026, 9, 1 + i % 28),
            note: 'فاتورة INV-${i.toString().padLeft(6, '0')}',
          ),
      ],
      invoices: <CustomerInvoice>[
        CustomerInvoice(
          id: 'i1',
          number: 'INV-000001',
          total: 100,
          createdAt: DateTime(2026, 9, 1),
          status: 'completed',
        ),
      ],
    );

    // 60 حركة بتعدّي صفحة A4 واحدة — الـMultiPage لازم يكمّل من غير خطأ.
    expect(isPdf(bytes), isTrue);
  });

  test('ملصق الباركود بـEAN-13 الصالح وبـCode128 لأي كود تاني', () async {
    expect(
      isPdf(
        await buildBarcodeLabelPdf(
          name: 'بيبسي كانز',
          barcode:
              '6221031234567'.substring(0, 12) + _ean13Check('622103123456'),
          price: 15,
        ),
      ),
      isTrue,
    );

    expect(
      isPdf(
        await buildBarcodeLabelPdf(
          name: 'منتج',
          barcode: 'PEP-330',
          price: 15,
          copies: 3,
        ),
      ),
      isTrue,
    );
  });

  const ReportTable table = ReportTable(
    title: 'تقرير المبيعات',
    subtitle: 'آخر 7 أيام • كل الفروع',
    headers: <String>['التاريخ', 'الفواتير', 'المبيعات'],
    numeric: <int>{1, 2},
    summary: <(String, String)>[('إجمالي المبيعات', '3,000.00 ج.م')],
    rows: <List<Object>>[
      <Object>['2026/09/14', 10, 1000.5],
      <Object>['2026/09/15', 20, 1999.5],
    ],
  );

  test('تصدير Excel بيكتب الأرقام كأرقام في ورقة من اليمين للشمال', () {
    final Excel excel = Excel.decodeBytes(buildReportExcel(table));
    final Sheet sheet = excel['التقرير'];

    expect(sheet.isRTL, isTrue);

    final List<List<Data?>> rows = sheet.rows;
    expect(rows.first.first?.value.toString(), 'تقرير المبيعات');

    final int headerIndex = rows.indexWhere(
      (List<Data?> r) => r.isNotEmpty && r.first?.value.toString() == 'التاريخ',
    );
    expect(headerIndex, greaterThan(0));

    final List<Data?> first = rows[headerIndex + 1];
    expect(first[1]?.value, isA<IntCellValue>());
    expect((first[1]!.value! as IntCellValue).value, 10);
    expect((first[2]!.value! as DoubleCellValue).value, 1000.5);
    expect(rows.length, headerIndex + 3);
  });

  test('تصدير PDF للتقرير وفاضي من غير بيانات', () async {
    expect(isPdf(await buildReportPdf(table, store)), isTrue);

    const ReportTable empty = ReportTable(
      title: 'تقرير المخزون',
      subtitle: 'كل الفروع',
      headers: <String>['القسم'],
      rows: <List<Object>>[],
    );
    expect(isPdf(await buildReportPdf(empty, store)), isTrue);
  });

  test('اسم الملف بيتشال منه الرموز اللي الويندوز بيرفضها', () {
    expect(safeFileName('تقرير: 2026/09/15?'), 'تقرير- 2026-09-15-');
  });

  test('الطباعة التلقائية مقفولة افتراضيًا وبتتحفظ', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    expect(await PrintPreferences.autoPrintReceipt(), isFalse);
    await PrintPreferences.setAutoPrintReceipt(true);
    expect(await PrintPreferences.autoPrintReceipt(), isTrue);
  });
}

/// رقم التحقق لـEAN-13 من أول 12 رقم.
String _ean13Check(String twelve) {
  int sum = 0;
  for (int i = 0; i < 12; i += 1) {
    sum += int.parse(twelve[i]) * (i.isEven ? 1 : 3);
  }
  return ((10 - sum % 10) % 10).toString();
}
