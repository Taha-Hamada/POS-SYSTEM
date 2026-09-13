import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_backend.dart';
import 'package:pos_system/mock_data/mock_data.dart';

const Size _desktop = Size(1600, 950);

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = _desktop;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(PosSystemApp(api: FakeBackend().client()));
  // التطبيق بيبدأ على شاشة انتظار لحد ما يقرا الجلسة المحفوظة.
  await tester.pumpAndSettle();
}

Future<void> _openScreen(WidgetTester tester, String navLabel) async {
  await _pumpApp(tester);
  // القائمة الجانبية بقت أطول من الشاشة، فبنزحلقها للعنصر الأول
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
  });

  group('لوحة التحكم', () {
    testWidgets('الرسوم والبطاقات والجداول بتظهر', (WidgetTester tester) async {
      await _openScreen(tester, 'لوحة التحكم');

      // البطاقات الأربعة
      expect(find.text('إجمالي المبيعات'), findsWidgets);
      expect(find.text('صافي الربح'), findsOneWidget);
      expect(find.text('عدد الفواتير'), findsOneWidget);
      expect(find.text('متوسط قيمة الفاتورة'), findsOneWidget);

      // الرسوم
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);

      // الجدولين
      expect(find.text('أفضل 5 منتجات مبيعًا'), findsOneWidget);
      expect(find.text('أفضل الفروع أداءً'), findsOneWidget);
    });

    testWidgets('تغيير الفترة بيحدّث الأرقام', (WidgetTester tester) async {
      await _openScreen(tester, 'لوحة التحكم');

      final double monthSales = MockData.seriesFor(days: 30)
          .fold<double>(0, (double s, SalesPoint p) => s + p.sales);
      expect(find.text(formatRounded(monthSales)), findsOneWidget);

      await tester.tap(find.text('آخر 7 أيام'));
      await tester.pumpAndSettle();

      final double weekSales = MockData.seriesFor(days: 7)
          .fold<double>(0, (double s, SalesPoint p) => s + p.sales);
      expect(find.text(formatRounded(weekSales)), findsOneWidget);
      expect(find.textContaining('آخر 7 أيام'), findsWidgets);
    });

    testWidgets('فلتر الفرع بيقلّل المبيعات بنسبة حصته', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'لوحة التحكم');

      await tester.tap(find.text('كل الفروع'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(MockData.branches[2].name).last);
      await tester.pumpAndSettle();

      // الرقم بيظهر في البطاقة وفي جدول الفروع
      final double branchSales =
          MockData.seriesFor(days: 30, branchId: MockData.branches[2].id)
              .fold<double>(0, (double s, SalesPoint p) => s + p.sales);
      expect(find.text(formatRounded(branchSales)), findsWidgets);
    });
  });

  group('المصروفات', () {
    testWidgets('الجدول والفلترة وإضافة مصروف', (WidgetTester tester) async {
      await _openScreen(tester, 'المصروفات');

      expect(find.text('صافي النقدية الحالي'), findsOneWidget);
      expect(find.text('إجمالي مصروفات الشهر'), findsOneWidget);
      expect(find.text('سجل المصروفات'), findsOneWidget);
      expect(find.text('معلّق'), findsWidgets);

      await tester.tap(find.text('إضافة مصروف'));
      await tester.pumpAndSettle();

      expect(find.text('مصروف جديد'), findsOneWidget);
      expect(find.text('المرفق'), findsOneWidget);

      // المبلغ إلزامي عشان الزر يشتغل
      await tester.enterText(find.byType(TextField).at(1), '750');
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ المصروف'));
      await tester.pumpAndSettle();

      expect(find.text('مصروف جديد'), findsNothing);
      expect(find.textContaining('750.00'), findsWidgets);
    });
  });

  group('الفروع', () {
    testWidgets('شبكة كروت الفروع بنقاط الحالة', (WidgetTester tester) async {
      await _openScreen(tester, 'الفروع');

      // اسم الفرع الحالي بيظهر كمان في مبدّل الفروع بالشريط العلوي
      for (final Branch b in MockData.branches) {
        expect(find.text(b.name), findsWidgets);
      }
      expect(find.text('مفتوح الآن'), findsNWidgets(2));
      expect(find.text('مغلق'), findsOneWidget);
      expect(find.text('مبيعات اليوم'), findsWidgets);
    });

    testWidgets('إضافة فرع جديد بيظهر في الشبكة', (WidgetTester tester) async {
      await _openScreen(tester, 'الفروع');

      await tester.tap(find.text('إضافة فرع جديد').first);
      await tester.pumpAndSettle();

      expect(find.text('فرع جديد'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'فرع الشيخ زايد');
      await tester.enterText(find.byType(TextField).at(1), 'الحي المتميز');
      await tester.pumpAndSettle();

      await tester.tap(find.text('إضافة الفرع'));
      await tester.pumpAndSettle();

      expect(find.text('فرع الشيخ زايد'), findsOneWidget);
      expect(find.text('قيد التجهيز'), findsOneWidget);
    });
  });

  group('الإعدادات', () {
    testWidgets('التنقل بين الأقسام وقسم الأجهزة', (WidgetTester tester) async {
      await _openScreen(tester, 'الإعدادات');

      expect(find.text('اسم المتجر'), findsOneWidget);

      await tester.tap(find.text('الأجهزة المتصلة').first);
      await tester.pumpAndSettle();

      // بطاقة لكل جهاز
      for (final ConnectedDevice d in MockData.devices) {
        expect(find.text(d.model), findsOneWidget);
      }
      expect(find.text('متصل'), findsNWidgets(3));
      expect(find.text('غير متصل'), findsOneWidget);
      expect(find.text('اختبار الاتصال'), findsNWidgets(4));

      // اختبار الاتصال بيغيّر حالة الزر
      await tester.tap(find.text('اختبار الاتصال').first);
      await tester.pump();
      expect(find.text('جارٍ الاختبار…'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('قسم الضرائب بيحسب المثال لحظيًا', (WidgetTester tester) async {
      await _openScreen(tester, 'الإعدادات');

      await tester.tap(find.text('الضرائب').first);
      await tester.pumpAndSettle();

      expect(find.text('نسبة الضريبة الأساسية'), findsOneWidget);
      expect(find.textContaining('مثال على منتج'), findsOneWidget);
    });
  });
}

/// اختصار لتنسيق المبالغ زي ما البطاقات بتعرضها
String formatRounded(double value) {
  final String s = value.round().toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return '$out ج.م';
}
