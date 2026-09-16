import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/utils/invoice_math.dart';

/// الحسبة اللي الكاشير بيشوفها لازم تطابق اللي السيرفر بيحصّله.
/// الأرقام المتوقعة هنا هي نفس نتائج اختبارات الباك اند.
void main() {
  PricedLine line({
    double price = 100,
    int qty = 1,
    bool taxable = true,
    double discount = 0,
  }) => PricedLine(
    unitPrice: price,
    quantity: qty,
    isTaxable: taxable,
    discountAmount: discount,
  );

  test('فاتورة بسيطة بضريبة 14%', () {
    final InvoiceTotals t = calculateTotals(
      lines: <PricedLine>[line()],
      taxRate: 0.14,
    );

    expect(t.subtotal, 100);
    expect(t.taxAmount, 14);
    expect(t.total, 114);
  });

  test('الكسور بتتقرّب لخانتين', () {
    final InvoiceTotals t = calculateTotals(
      lines: <PricedLine>[line(price: 12.33, qty: 3)],
      taxRate: 0.14,
    );

    expect(t.subtotal, 36.99);
    expect(t.taxAmount, 5.18);
    expect(t.total, 42.17);
  });

  test('خصم سطر بيقلّل الوعاء الضريبي', () {
    final InvoiceTotals t = calculateTotals(
      lines: <PricedLine>[line(discount: 10)],
      taxRate: 0.14,
    );

    expect(t.lineDiscountTotal, 10);
    expect(t.taxAmount, 12.6);
    expect(t.total, 102.6);
  });

  test('خصم الفاتورة فوق خصم السطور', () {
    final InvoiceTotals t = calculateTotals(
      lines: <PricedLine>[line(discount: 10), line(price: 200)],
      taxRate: 0.14,
      // 5% على 290
      invoiceDiscount: 14.5,
    );

    expect(t.subtotal, 300);
    expect(t.lineDiscountTotal, 10);
    expect(t.invoiceDiscount, 14.5);
    expect(t.taxAmount, 38.57);
    expect(t.total, 314.07);
  });

  test('الأصناف المعفاة مبتدخلش الوعاء', () {
    final InvoiceTotals t = calculateTotals(
      lines: <PricedLine>[line(), line(taxable: false)],
      taxRate: 0.14,
    );

    expect(t.subtotal, 200);
    expect(t.taxAmount, 14);
    expect(t.total, 214);
  });

  test('خصم الفاتورة بيتوزع على الوعاء بالتناسب', () {
    final InvoiceTotals t = calculateTotals(
      lines: <PricedLine>[line(), line(taxable: false)],
      taxRate: 0.14,
      invoiceDiscount: 40,
    );

    // الخاضع نص الصافي، فنص الخصم بس بيقلله: 100 − 20 = 80
    expect(t.taxableBase, 80);
    expect(t.taxAmount, 11.2);
    expect(t.total, 171.2);
  });

  test('الخصم مبيعديش قيمة الفاتورة', () {
    final InvoiceTotals t = calculateTotals(
      lines: <PricedLine>[line(price: 50)],
      taxRate: 0,
      invoiceDiscount: 500,
    );

    expect(t.invoiceDiscount, 50);
    expect(t.total, 0);
  });

  test('خصم المستوى قبل اليدوي بنفس أرقام السيرفر', () {
    // نفس المثال اللي اتحسب على invoice.pricing.js في الباك اند: 129.13.
    final InvoiceTotals t = calculateTotals(
      lines: <PricedLine>[
        line(price: 10, qty: 3, discount: 10),
        line(price: 4, qty: 10, discount: 8),
        line(price: 100, qty: 1, taxable: false, discount: 5),
      ],
      taxRate: 0.14,
      invoiceDiscountPercent: 10,
      tierDiscountPercent: 7,
    );

    expect(t.subtotal, 170);
    expect(t.lineDiscountTotal, 23);
    expect(t.tierDiscount, 10.29);
    expect(t.manualDiscount, 13.67);
    expect(t.invoiceDiscount, 23.96);
    expect(t.taxAmount, 6.09);
    expect(t.total, 129.13);
  });

  test('الخصم الثابت مبيعديش المتبقي بعد خصم المستوى', () {
    final InvoiceTotals t = calculateTotals(
      lines: <PricedLine>[line(price: 100)],
      taxRate: 0,
      invoiceDiscount: 500,
      tierDiscountPercent: 10,
    );

    expect(t.tierDiscount, 10);
    expect(t.manualDiscount, 90);
    expect(t.total, 0);
  });

  test('فاتورة فاضية بترجع أصفار', () {
    final InvoiceTotals t = calculateTotals(
      lines: <PricedLine>[],
      taxRate: 0.14,
    );

    expect(t.subtotal, 0);
    expect(t.taxAmount, 0);
    expect(t.total, 0);
  });
}
