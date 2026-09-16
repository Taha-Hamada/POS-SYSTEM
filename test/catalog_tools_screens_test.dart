import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_backend.dart';

const Size _desktop = Size(1600, 950);

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = _desktop;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(PosSystemApp(api: FakeBackend().client()));
  await tester.pumpAndSettle();
}

Future<void> _openScreen(WidgetTester tester, String navLabel) async {
  await _pumpApp(tester);
  final Finder item = find.text(navLabel).first;
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

/// شاشات تنبيهات المخزون وسجل المرتجعات والأقسام على الباك اند المزيّف.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'pos.access_token': 'fake-access',
      'pos.refresh_token': 'fake-refresh',
    });
  });

  testWidgets('الجرس بيفتح تنبيهات المخزون بالنواقص والصلاحية', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    // الضغط بالـTooltip عشان العدّاد اللي فوق الأيقونة مايبلعش الضغطة.
    await tester.tap(find.byTooltip('2 تنبيه مخزون'));
    await tester.pumpAndSettle();

    expect(find.text('تنبيهات المخزون'), findsOneWidget);
    expect(find.text('نواقص المخزون'), findsOneWidget);
    expect(find.text('منخفض'), findsOneWidget);
    expect(find.text('باقي 5 يوم'), findsOneWidget);
  });

  testWidgets('سجل المرتجعات بيعرض المرتجعات وإجمالياتها', (
    WidgetTester tester,
  ) async {
    await _openScreen(tester, 'المرتجعات');

    await tester.tap(find.text('سجل المرتجعات').first);
    await tester.pumpAndSettle();

    expect(find.text('RET-000001'), findsOneWidget);
    expect(find.text('INV-000001'), findsOneWidget);
    expect(find.text('كاش'), findsOneWidget);
  });

  testWidgets('إضافة قسم من شاشة الأقسام', (WidgetTester tester) async {
    await _openScreen(tester, 'المنتجات');

    await tester.tap(find.text('الأقسام'));
    await tester.pumpAndSettle();

    expect(find.text('أقسام المنتجات'), findsOneWidget);
    expect(find.text('مشروبات'), findsWidgets);

    await tester.tap(find.text('قسم جديد'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'منظفات',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('اتضاف القسم'), findsOneWidget);
    expect(find.text('منظفات'), findsOneWidget);

    // الرجوع بيقفل الأقسام ويرجّع قايمة المنتجات.
    await tester.tap(find.byTooltip('رجوع للمنتجات'));
    await tester.pumpAndSettle();
    expect(find.text('SKU'), findsOneWidget);
  });

  testWidgets('حوار تعديل الأسعار بيعاين السعر الجديد', (
    WidgetTester tester,
  ) async {
    await _openScreen(tester, 'المنتجات');

    await tester.tap(find.text('تعديل الأسعار'));
    await tester.pumpAndSettle();

    expect(find.text('تعديل الأسعار الجماعي'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '10',
    );
    await tester.pumpAndSettle();

    expect(find.text('معاينة'), findsOneWidget);
    expect(find.text('تطبيق التعديل'), findsOneWidget);
  });
}
