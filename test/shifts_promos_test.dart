import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos_system/features/returns/controllers/returns_controller.dart';

import 'support/fake_backend.dart';
import 'package:pos_system/features/cashier_shift/screens/open_shift_dialog.dart';

const Size _desktop = Size(1600, 950);

late FakeBackend _backend;

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = _desktop;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(PosSystemApp(api: _backend.client()));
  // التطبيق بيبدأ على شاشة انتظار لحد ما يقرا الجلسة المحفوظة.
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

void main() {
  setUp(() {
    // الشاشات بقت بتقرا من الـ API، فبنشغّلها على باك اند مزيّف
    // وبجلسة محفوظة عشان التطبيق يعدّي شاشة الدخول.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'pos.access_token': 'fake-access',
      'pos.refresh_token': 'fake-refresh',
    });

    _backend = FakeBackend();
  });

  group('الورديات', () {
    testWidgets('إغلاق الوردية بيحسب الفرق ويلوّنه', (
      WidgetTester tester,
    ) async {
      // درج متوقّع = 2000 + 8000 + 500 − 300 = 10200
      _backend.openShift(
        2000,
        cashSales: 8000,
        cashIn: 500,
        cashOut: 300,
        salesTotal: 12000,
        invoicesCount: 24,
      );

      await _pumpApp(tester);

      await tester.tap(find.text('إغلاق الوردية'));
      await tester.pumpAndSettle();

      expect(find.text('العدّ الفعلي للنقدية'), findsOneWidget);
      expect(find.text('Cash In'), findsOneWidget);
      expect(find.text('Cash Out'), findsOneWidget);
      expect(find.text('في انتظار العدّ'), findsOneWidget);

      const double expected = 10200;

      // عدّ مطابق تمامًا → أخضر
      await tester.enterText(
        find.byType(TextField).first,
        expected.toStringAsFixed(2),
      );
      await tester.pumpAndSettle();
      expect(find.text('مطابق تمامًا'), findsOneWidget);

      // عدّ أقل → عجز
      await tester.enterText(
        find.byType(TextField).first,
        (expected - 150).toStringAsFixed(2),
      );
      await tester.pumpAndSettle();
      expect(find.text('عجز في الدرج'), findsOneWidget);
      expect(find.text('− 150.00 ج.م'), findsOneWidget);
    });

    testWidgets('بدء وردية جديدة بالـNumpad', (WidgetTester tester) async {
      _backend.openShift(2000);
      await _pumpApp(tester);

      // نقفل الوردية الحالية الأول
      await tester.tap(find.text('إغلاق الوردية'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '20000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('إغلاق الوردية').last);
      await tester.pumpAndSettle();

      expect(find.text('الوردية مغلقة'), findsOneWidget);

      // نبدأ وردية جديدة
      await tester.tap(find.text('بدء وردية'));
      await tester.pumpAndSettle();

      expect(find.text('بدء وردية جديدة'), findsOneWidget);
      expect(find.text('الرصيد الافتتاحي في الدرج'), findsOneWidget);

      // نحصر البحث جوه الحوار — الرقم 5 موجود كمان في عدّاد الإشعارات
      await tester.tap(
        find.descendant(
          of: find.byType(OpenShiftDialog),
          matching: find.text('5'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(OpenShiftDialog),
          matching: find.text('5'),
        ),
        findsWidgets,
      );

      await tester.tap(find.text('بدء الوردية'));
      await tester.pumpAndSettle();
      expect(find.text('الوردية مفتوحة'), findsOneWidget);
    });
  });

  group('المرتجعات', () {
    testWidgets('البحث عن فاتورة واختيار أصناف للإرجاع', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'المرتجعات');

      expect(find.text('ابدأ بالبحث عن الفاتورة'), findsOneWidget);

      // البحث بقى بيروح للسيرفر برقم الفاتورة المطبوع.
      await tester.enterText(find.byType(TextField).first, 'INV-000001');
      await tester.tap(find.text('بحث'));
      await tester.pumpAndSettle();

      expect(find.text('INV-000001'), findsWidgets);
      expect(find.text('سبب الإرجاع'), findsOneWidget);
      expect(find.text('طريقة الاسترداد'), findsOneWidget);

      // الزر متعطّل لحد ما نختار صنف وسبب
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      expect(find.text('لازم تختار سبب الإرجاع قبل التأكيد'), findsOneWidget);

      await tester.tap(find.text('اختر السبب…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kReturnReasons.first).last);
      await tester.pumpAndSettle();

      expect(find.text('لازم تختار سبب الإرجاع قبل التأكيد'), findsNothing);
      expect(find.text('تأكيد المرتجع'), findsOneWidget);
    });
  });

  group('العروض', () {
    testWidgets('شبكة الكروت والفلترة بالحالة', (WidgetTester tester) async {
      await _openScreen(tester, 'العروض والخصومات');

      expect(find.text('خصم الصيف على المشروبات'), findsOneWidget);
      expect(find.text('اشترِ واحصل'), findsWidgets);

      // فلترة على المجدول (أول نتيجة هي شريحة الفلتر مش الـBadge)
      await tester.tap(find.text('مجدول').first);
      await tester.pumpAndSettle();

      expect(find.text('عرض العودة للمدارس'), findsOneWidget);
      expect(find.text('خصم الصيف على المشروبات'), findsNothing);
    });

    testWidgets('حوار إنشاء عرض جديد بتاريخين', (WidgetTester tester) async {
      await _openScreen(tester, 'العروض والخصومات');

      await tester.tap(find.text('إنشاء عرض جديد'));
      await tester.pumpAndSettle();

      expect(find.text('عرض جديد'), findsOneWidget);
      expect(find.text('تاريخ البداية'), findsOneWidget);
      expect(find.text('تاريخ النهاية'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'عرض تجريبي');
      await tester.enterText(find.byType(TextField).at(1), '25');
      await tester.pumpAndSettle();

      await tester.tap(find.text('إنشاء العرض'));
      await tester.pumpAndSettle();

      expect(find.textContaining('عرض تجريبي'), findsWidgets);
    });
  });

  group('برنامج الولاء', () {
    testWidgets('المستويات الثلاثة وجدول أعلى العملاء', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'برنامج الولاء');

      expect(find.text('آلية كسب النقاط'), findsOneWidget);
      expect(find.text('فضي'), findsWidgets);
      expect(find.text('ذهبي'), findsWidgets);
      expect(find.text('بلاتيني'), findsWidgets);
      expect(find.text('أعلى العملاء نقاطًا'), findsOneWidget);

      // أعلى عميل نقاطًا في الباك اند المزيّف
      expect(find.text('محمد أحمد'), findsOneWidget);

      // تغيير معدّل الكسب بيحدّث المثال لحظيًا
      await tester.enterText(find.byType(TextField).first, '2');
      await tester.pumpAndSettle();
      expect(find.textContaining('1,000 نقطة'), findsOneWidget);
    });
  });
}
