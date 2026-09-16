import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/widgets/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_backend.dart';

const Size _desktop = Size(1600, 950);

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

/// حركة الكاش، صلاحيات الموظف، الباركود، والخروج من كل الأجهزة.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'pos.access_token': 'fake-access',
      'pos.refresh_token': 'fake-refresh',
    });
  });

  testWidgets('سحب من الدرج بيتسجل من الشريط الجانبي', (
    WidgetTester tester,
  ) async {
    final FakeBackend backend = FakeBackend()..openShift(1000, cashSales: 400);
    await _pumpApp(tester, backend: backend);

    await tester.tap(find.text('حركة كاش'));
    await tester.pumpAndSettle();

    expect(find.text('حركة كاش على الدرج'), findsOneWidget);
    // السحب هو الافتراضي، والدرج فيه 1400.
    expect(find.textContaining('في الدرج دلوقتي'), findsOneWidget);

    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          )
          .first,
      '300',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('توريد للخزنة'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تسجيل السحب'));
    await tester.pumpAndSettle();

    expect(find.textContaining('اتسجل سحب'), findsOneWidget);
  });

  testWidgets('السحب أكبر من الدرج بيترفض قبل ما يتبعت', (
    WidgetTester tester,
  ) async {
    final FakeBackend backend = FakeBackend()..openShift(100);
    await _pumpApp(tester, backend: backend);

    await tester.tap(find.text('حركة كاش'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          )
          .first,
      '5000',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('السحب أكبر من الموجود'), findsOneWidget);
  });

  testWidgets('صلاحيات موظف بعينه بتتحفظ فوق دوره', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _open(tester, 'الموظفين');

    // أزرار الصف بتبان مع مرور الماوس بس.
    final TestGesture pointer = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await pointer.addPointer(location: Offset.zero);
    addTearDown(pointer.removePointer);
    await pointer.moveTo(tester.getCenter(find.text('سارة الكاشير')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الصلاحيات').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('صلاحيات '), findsWidgets);
    expect(find.text('من الدور'), findsWidgets);

    // أول صلاحية مش في باقة الدور بتتزوّد للموظف.
    await tester.tap(find.text('يمكنه إلغاء فاتورة'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(find.textContaining('اتحفظت صلاحيات'), findsOneWidget);
  });

  testWidgets('معاينة الباركود بترسم باركود حقيقي بعد التوليد', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _open(tester, 'المنتجات');

    await tester.tap(find.text('إضافة منتج'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الباركود').first);
    await tester.pumpAndSettle();

    expect(find.text('مفيش باركود لسه'), findsOneWidget);

    await tester.tap(find.text('توليد باركود جديد'));
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsWidgets);
    expect(find.text('مفيش باركود لسه'), findsNothing);
  });

  testWidgets('الخروج من كل الأجهزة بيرجّع لشاشة الدخول', (
    WidgetTester tester,
  ) async {
    final FakeBackend backend = await _pumpApp(tester);

    await tester.tap(find.byTooltip('حسابك').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('خروج من كل الأجهزة'));
    await tester.pumpAndSettle();

    expect(
      backend.requestedPaths.any((String p) => p.endsWith('/auth/logout-all')),
      isTrue,
    );
    expect(find.text(kNavItems.first.label), findsNothing);
  });
}
