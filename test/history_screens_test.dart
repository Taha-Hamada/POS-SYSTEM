import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/widgets/status_badge.dart';
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

Finder _dialogFields() => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(TextField),
);

/// سجل الفواتير والإلغاء، سجل الورديات، وتغيير كلمة السر على الباك اند المزيّف.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'pos.access_token': 'fake-access',
      'pos.refresh_token': 'fake-refresh',
    });
  });

  testWidgets('سجل الفواتير بيعرض الفواتير وبيلغي فاتورة بسبب', (
    WidgetTester tester,
  ) async {
    await _openScreen(tester, 'الفواتير');

    expect(find.text('سجل الفواتير'), findsOneWidget);
    expect(find.text('INV-000101'), findsOneWidget);
    expect(find.text('INV-000102'), findsOneWidget);
    expect(find.widgetWithText(StatusBadge, 'ملغاة'), findsNothing);

    await tester.tap(find.text('INV-000101'));
    await tester.pumpAndSettle();
    expect(find.text('فاتورة INV-000101'), findsOneWidget);
    expect(find.text('بيبسي كانز'), findsOneWidget);

    await tester.tap(find.text('إلغاء الفاتورة'));
    await tester.pumpAndSettle();

    // السبب لازم يبقى 3 حروف على الأقل قبل ما التأكيد يشتغل.
    await tester.enterText(_dialogFields().last, 'غلط في الأصناف');
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد الإلغاء'));
    await tester.pumpAndSettle();

    expect(find.text('اتلغت الفاتورة INV-000101'), findsOneWidget);
    expect(find.widgetWithText(StatusBadge, 'ملغاة'), findsOneWidget);
  });

  testWidgets('سجل الورديات بيعرض نتيجة التقفيل والتفاصيل', (
    WidgetTester tester,
  ) async {
    await _openScreen(tester, 'الورديات');

    expect(find.text('سجل الورديات'), findsOneWidget);
    expect(find.text('SH-00007'), findsOneWidget);
    expect(find.text('كاشير الصباح'), findsOneWidget);

    await tester.tap(find.text('SH-00007'));
    await tester.pumpAndSettle();

    expect(find.text('وردية SH-00007'), findsOneWidget);
    expect(find.text('عجز'), findsOneWidget);
    expect(find.text('ملاحظة: فكة ناقصة'), findsOneWidget);
  });

  testWidgets('تغيير كلمة السر من قايمة الحساب', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byTooltip('حسابك').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تغيير كلمة السر'));
    await tester.pumpAndSettle();

    Future<void> fill(String current) async {
      await tester.enterText(_dialogFields().at(0), current);
      await tester.enterText(_dialogFields().at(1), 'New@12345');
      await tester.enterText(_dialogFields().at(2), 'New@12345');
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
    }

    await fill('Wrong@123');
    expect(find.text('كلمة السر الحالية غير صحيحة'), findsOneWidget);

    await fill('Old@12345');
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('اتغيرت كلمة السر'), findsOneWidget);
  });
}
