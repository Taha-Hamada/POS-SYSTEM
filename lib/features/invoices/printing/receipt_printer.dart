import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/store_settings.dart';
import '../../../core/printing/pdf_kit.dart';
import '../../../core/printing/print_job.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../data/invoices_repository.dart';
import '../models/invoice_record.dart';
import 'receipt_pdf.dart';

/// بيجيب الفاتورة من السيرفر ويطبع إيصالها.
///
/// الإيصال بيتبني من نسخة السيرفر مش من السلة، عشان الأرقام المطبوعة
/// تبقى هي الأرقام المتسجّلة فعلًا (العروض والتقريب والضريبة).
Future<bool> printInvoiceReceipt(
  BuildContext context, {
  required String invoiceId,
  StoreSettings? store,
}) async {
  final StoreSettings settings = store ?? storeSettingsOf(context);

  final InvoiceRecord invoice;
  try {
    invoice = await InvoicesRepository(
      context.read<ApiClient>(),
    ).fetchOne(invoiceId);
  } on ApiException catch (exception) {
    if (context.mounted) {
      showAppSnackBar(context, exception.message, isError: true);
    }
    return false;
  }

  if (!context.mounted) return false;

  return printDocument(
    context,
    name: 'إيصال ${invoice.number}',
    format: PdfKit.rollFormat(settings.receiptWidthMm),
    build: (format) =>
        buildReceiptPdf(invoice: invoice, store: settings, format: format),
  );
}
