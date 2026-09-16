import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'print_preferences.dart';

enum SavedFileType { pdf, excel }

/// مخرج المستندات: الطباعة وحفظ الملفات.
///
/// كل الشاشات بتطبع وتحفظ من هنا، عشان الاختبارات تبدّله بمخرج بيسجّل
/// الطلبات بدل ما يفتح حوار طباعة الويندوز.
abstract class DocumentOutput {
  static DocumentOutput instance = const SystemDocumentOutput();

  /// بيفتح حوار الطباعة. بيرجّع false لو المستخدم لغى.
  Future<bool> printPdf({
    required String name,
    required PdfPageFormat format,
    required Future<Uint8List> Function(PdfPageFormat format) build,
  });

  /// بيفتح حوار «حفظ باسم». بيرجّع المسار، أو null لو اتلغى.
  Future<String?> save({
    required String name,
    required Uint8List bytes,
    required SavedFileType type,
  });
}

class SystemDocumentOutput implements DocumentOutput {
  const SystemDocumentOutput();

  @override
  Future<bool> printPdf({
    required String name,
    required PdfPageFormat format,
    required Future<Uint8List> Function(PdfPageFormat format) build,
  }) async {
    final ({String url, String name})? printer =
        await PrintPreferences.receiptPrinter();

    // اتحددت طابعة للجهاز ده؟ يبقى الإيصال يروح لها على طول من غير حوار.
    if (printer != null) {
      return Printing.directPrintPdf(
        printer: Printer(url: printer.url, name: printer.name),
        name: name,
        format: format,
        dynamicLayout: false,
        onLayout: build,
      );
    }

    return Printing.layoutPdf(
      name: name,
      format: format,
      // المقاس بيفضل اللي اخترناه (رول الإيصال أو الملصق) مش ورق الطابعة.
      dynamicLayout: false,
      onLayout: build,
    );
  }

  @override
  Future<String?> save({
    required String name,
    required Uint8List bytes,
    required SavedFileType type,
  }) => FileSaver.instance.saveAs(
    name: name,
    bytes: bytes,
    fileExtension: type == SavedFileType.pdf ? 'pdf' : 'xlsx',
    mimeType: type == SavedFileType.pdf
        ? MimeType.pdf
        : MimeType.microsoftExcel,
  );
}
