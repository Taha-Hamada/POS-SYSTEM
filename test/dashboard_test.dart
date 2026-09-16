import 'package:fl_chart/fl_chart.dart';
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

      // الباك اند المزيّف بيدي 1000 لكل يوم.
      expect(find.text(formatRounded(30000)), findsOneWidget);

      await tester.tap(find.text('آخر 7 أيام'));
      await tester.pumpAndSettle();

      expect(find.text(formatRounded(7000)), findsOneWidget);
      expect(find.textContaining('آخر 7 أيام'), findsWidgets);
    });

    testWidgets('فلتر الفرع بيقلّل المبيعات بنسبة حصته', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'لوحة التحكم');

      await tester.tap(find.text('كل الفروع'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('فرع المعادي').last);
      await tester.pumpAndSettle();

      // نصيب الفرع 40% من 30000
      expect(find.text(formatRounded(12000)), findsWidgets);
    });
  });

  group('المصروفات', () {
    testWidgets('الجدول والفلترة وإضافة مصروف', (WidgetTester tester) async {
      await _openScreen(tester, 'المصروفات');

      expect(find.text('إجمالي المصروفات المطابقة'), findsOneWidget);
      expect(find.text('بانتظار الاعتماد'), findsWidgets);
      expect(find.text('سجل المصروفات'), findsOneWidget);
      expect(find.text('كهرباء'), findsWidgets);

      await tester.tap(find.text('إضافة مصروف'));
      await tester.pumpAndSettle();

      expect(find.text('مصروف جديد'), findsOneWidget);

      // شريط البحث ورا الحوار برضو TextField، فبنحصر البحث جوه الحوار.
      final Finder dialogFields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      );

      // البند والمبلغ إلزاميين عشان الزر يشتغل — السيرفر بيرفض غير كده.
      await tester.enterText(dialogFields.at(0), 'نثريات');
      await tester.enterText(dialogFields.at(1), '750');
      await tester.pumpAndSettle();

      await tester.tap(find.text('حفظ المصروف'));
      await tester.pumpAndSettle();

      expect(find.text('مصروف جديد'), findsNothing);
      expect(find.text('نثريات'), findsWidgets);
      expect(find.textContaining('750'), findsWidgets);
    });
  });

  group('الفروع', () {
    testWidgets('شبكة كروت الفروع بأرقامها من السيرفر', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'الفروع');

      // اسم فرع المستخدم بيظهر كمان في مؤشر الفرع بالشريط العلوي
      expect(find.text('الفرع الرئيسي'), findsWidgets);
      expect(find.text('فرع المعادي'), findsOneWidget);
      // حالة كل فرع بكوده — بطاقة الإحصائيات فوق فيها «مفتوح الآن» برضه.
      expect(find.text('مفتوح الآن • MAIN'), findsOneWidget);
      expect(find.text('مفتوح الآن • MAAD'), findsOneWidget);
      expect(find.text('2 مفتوح الآن'), findsOneWidget);
      expect(find.text('مبيعات اليوم'), findsWidgets);
    });

    testWidgets('حوار إضافة فرع بيحفظ على السيرفر ويقفل', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'الفروع');

      await tester.tap(find.text('إضافة فرع جديد').first);
      await tester.pumpAndSettle();

      expect(find.text('فرع جديد'), findsOneWidget);

      final Finder dialogFields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      );

      // الاسم والكود إلزاميين — السيرفر بيرفض غير كده.
      await tester.enterText(dialogFields.at(0), 'فرع الشيخ زايد');
      await tester.enterText(dialogFields.at(1), 'ZAYED');
      await tester.pumpAndSettle();

      await tester.tap(find.text('إضافة الفرع'));
      await tester.pumpAndSettle();

      expect(find.text('فرع جديد'), findsNothing);
      expect(find.text('اتضاف الفرع الجديد'), findsOneWidget);
    });
  });

  group('الإعدادات', () {
    testWidgets('التنقل بين الأقسام وقسم الأجهزة', (WidgetTester tester) async {
      await _openScreen(tester, 'الإعدادات');

      expect(find.text('اسم المتجر'), findsOneWidget);

      await tester.tap(find.text('الأجهزة المتصلة').first);
      await tester.pumpAndSettle();

      // القسم بيقرا طابعات الجهاز الحقيقية — في الاختبار مفيش منصة طباعة،
      // فبيخلص بقايمة فاضية بدل ما يفضل بيحمّل.
      expect(find.textContaining('طابعات الجهاز ده'), findsOneWidget);
      expect(find.text('مفيش طابعات متسطبة على الجهاز'), findsOneWidget);
      expect(find.text('اسأل كل مرة (حوار الطباعة)'), findsOneWidget);
      expect(find.textContaining('قارئ الباركود والميزان'), findsOneWidget);
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
