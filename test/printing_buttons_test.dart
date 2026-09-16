import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pos_system/core/printing/document_output.dart';
import 'package:pos_system/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_backend.dart';

const Size _desktop = Size(1600, 950);

/// مخرج بيسجّل طلبات الطباعة والحفظ بدل ما يفتح حوارات الويندوز.
class _RecordingOutput implements DocumentOutput {
  final List<({String name, PdfPageFormat format})> printed =
      <({String name, PdfPageFormat format})>[];
  final List<({String name, SavedFileType type, int size})> saved =
      <({String name, SavedFileType type, int size})>[];

  @override
  Future<bool> printPdf({
    required String name,
    required PdfPageFormat format,
    required Future<Uint8List> Function(PdfPageFormat format) build,
  }) async {
    printed.add((name: name, format: format));
    return true;
  }

  @override
  Future<String?> save({
    required String name,
    required Uint8List bytes,
    required SavedFileType type,
  }) async {
    saved.add((name: name, type: type, size: bytes.length));
    return 'C:/Exports/$name';
  }
}

Future<FakeBackend> _pumpApp(
  WidgetTester tester, {
  FakeBackend? backend,
}) async {
  final FakeBackend fake = backend ?? FakeBackend();
  tester.view.physicalSize = _desktop;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(PosSystemApp(api: fake.client()));
  await tester.pumpAndSettle();
  return fake;
}

Future<void> _open(WidgetTester tester, String navLabel) async {
  final Finder item = find.text(navLabel).first;
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

/// الأزرار اللي كانت فاضية بقت بتطبع وبتصدّر فعلًا.
void main() {
  late _RecordingOutput output;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'pos.access_token': 'fake-access',
      'pos.refresh_token': 'fake-refresh',
    });
    output = _RecordingOutput();
    DocumentOutput.instance = output;
  });

  tearDown(() => DocumentOutput.instance = const SystemDocumentOutput());

  testWidgets('تصدير التقرير Excel بيحفظ ملف باسم التقرير', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _open(tester, 'التقارير');

    await tester.tap(find.text('تصدير Excel'));
    await tester.pumpAndSettle();

    expect(output.saved, hasLength(1));
    expect(output.saved.single.type, SavedFileType.excel);
    expect(output.saved.single.name, startsWith('تقرير المبيعات - '));
    expect(output.saved.single.size, greaterThan(0));
    expect(find.textContaining('اتحفظ الملف'), findsOneWidget);
  });

  testWidgets('تصدير التقرير PDF بيبني الملف بالخط العربي', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _open(tester, 'التقارير');

    // بناء الـPDF بيقرا الخط من الأصول، فبيحتاج وقت حقيقي.
    await tester.runAsync(() async {
      await tester.tap(find.text('تصدير PDF'));
      for (int i = 0; i < 50 && output.saved.isEmpty; i += 1) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pumpAndSettle();

    expect(output.saved.single.type, SavedFileType.pdf);
    expect(output.saved.single.size, greaterThan(1000));
  });

  testWidgets('إعادة طباعة الإيصال من سجل الفواتير على رول 80', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _open(tester, 'الفواتير');

    await tester.tap(find.text('INV-000101'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('طباعة الإيصال'));
    await tester.pumpAndSettle();

    expect(output.printed.single.name, 'إيصال INV-000101');
    expect(
      output.printed.single.format.width,
      closeTo(80 * PdfPageFormat.mm, 0.01),
    );
  });

  testWidgets('تقرير الوردية بيتطبع من حوار الإغلاق', (
    WidgetTester tester,
  ) async {
    final FakeBackend backend = FakeBackend()..openShift(1000, cashSales: 400);
    await _pumpApp(tester, backend: backend);

    await tester.tap(find.text('إغلاق الوردية').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('طباعة تقرير الوردية'));
    await tester.pumpAndSettle();

    expect(output.printed.single.name, 'تقرير وردية SH-00001');
  });

  testWidgets('سجل الورديات بيعيد طباعة تقرير الوردية المقفولة', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _open(tester, 'الورديات');

    await tester.tap(find.text('SH-00007'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('طباعة التقرير'));
    await tester.pumpAndSettle();

    expect(output.printed.single.name, 'تقرير وردية SH-00007');
  });
}
