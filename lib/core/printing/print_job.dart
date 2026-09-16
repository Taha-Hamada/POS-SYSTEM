import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../models/store_settings.dart';
import '../session/settings_controller.dart';
import '../widgets/app_snack_bar.dart';
import 'document_output.dart';

/// إعدادات المتجر لو متاحة في الشجرة، وإلا القيم الافتراضية.
///
/// الحوارات بتتفتح على الـNavigator الرئيسي فوق الـShell، فمش دايمًا
/// بتشوف الـSettingsController.
StoreSettings storeSettingsOf(BuildContext context) {
  // الحوارات اللي محتاجاها بتتلفّ بنسخة منها وقت الفتح.
  try {
    return context.read<StoreSettings>();
  } on ProviderNotFoundException {
    // مش ملفوفة — نجرّب إعدادات الـShell.
  }

  try {
    return context.read<SettingsController>().settings;
  } on ProviderNotFoundException {
    return const StoreSettings();
  }
}

String _failureMessage(Object error) => switch (error) {
  ApiException(:final String message) => message,
  MissingPluginException() => 'الطباعة مش مدعومة على الجهاز ده',
  PlatformException(:final String? message) =>
    message ?? 'حصلت مشكلة في الطابعة',
  _ => 'مقدرناش نجهّز المستند',
};

/// بيطبع PDF وبيعرض أي فشل كرسالة بدل ما يوقع الشاشة.
///
/// بيرجّع true لو اتبعت للطابعة.
Future<bool> printDocument(
  BuildContext context, {
  required String name,
  required PdfPageFormat format,
  required Future<Uint8List> Function(PdfPageFormat format) build,
}) async {
  try {
    return await DocumentOutput.instance.printPdf(
      name: name,
      format: format,
      build: build,
    );
  } catch (error) {
    if (context.mounted) {
      showAppSnackBar(context, _failureMessage(error), isError: true);
    }
    return false;
  }
}

/// بيجهّز ملف ويفتح حوار «حفظ باسم»، وبيقول للمستخدم اتحفظ فين.
Future<void> saveDocument(
  BuildContext context, {
  required String name,
  required SavedFileType type,
  required Future<Uint8List> Function() build,
}) async {
  try {
    final Uint8List bytes = await build();
    final String? path = await DocumentOutput.instance.save(
      name: name,
      bytes: bytes,
      type: type,
    );
    if (path == null || !context.mounted) return;

    showAppSnackBar(
      context,
      path.isEmpty ? 'اتحفظ الملف' : 'اتحفظ الملف: $path',
      width: 520,
    );
  } catch (error) {
    if (context.mounted) {
      showAppSnackBar(context, _failureMessage(error), isError: true);
    }
  }
}

/// اسم ملف آمن: من غير الرموز اللي الويندوز بيرفضها.
String safeFileName(String value) =>
    value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-').trim();
