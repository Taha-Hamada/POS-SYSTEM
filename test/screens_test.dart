import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_backend.dart';
import 'package:pos_system/features/purchase_orders/screens/receive_goods_dialog.dart';

const Size _desktop = Size(1600, 950);

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = _desktop;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(PosSystemApp(api: FakeBackend().client()));
  // التطبيق بيبدأ على شاشة انتظار لحد ما يقرا الجلسة المحفوظة.
  await tester.pumpAndSettle();
}

/// يفتح شاشة من القائمة الجانبية (أول نتيجة هي عنصر الـSidebar)
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
  });

  group('المشتريات', () {
    testWidgets('جدول أوامر الشراء بيظهر بالحالات الأربعة', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'المشتريات');

      expect(find.text('أوامر الشراء'), findsWidgets);
      expect(find.text('مسودة'), findsWidgets);
      expect(find.text('مؤكد'), findsWidgets);
      expect(find.text('مستلم جزئيًا'), findsWidgets);
      expect(find.text('مكتمل'), findsWidgets);
    });

    testWidgets('الضغط على أمر مؤكد بيفتح Modal استلام البضاعة', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'المشتريات');

      // PO-00001 أمر مؤكد جاهز للاستلام
      await tester.tap(find.text('PO-00001'));
      await tester.pumpAndSettle();

      expect(find.text('استلام البضاعة'), findsOneWidget);
      expect(find.text('الكمية المستلمة'), findsOneWidget);
      // "نسبة الاستلام" موجودة كمان كعمود في الجدول اللي ورا الحوار
      expect(
        find.descendant(
          of: find.byType(ReceiveGoodsDialog),
          matching: find.text('نسبة الاستلام'),
        ),
        findsOneWidget,
      );
      // استلام الكل بيخلي النسبة 100%
      await tester.tap(find.text('استلام الكل'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(ReceiveGoodsDialog),
          matching: find.text('100%'),
        ),
        findsOneWidget,
      );
      expect(find.text('إتمام الاستلام'), findsOneWidget);
    });

    testWidgets('شاشة أمر شراء جديد بتحسب الإجمالي لحظيًا', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'المشتريات');

      await tester.tap(find.text('أمر شراء جديد'));
      await tester.pumpAndSettle();

      expect(find.text('إجمالي الأمر'), findsOneWidget);
      expect(find.text('لم تتم إضافة أصناف بعد'), findsOneWidget);

      await tester.tap(find.text('إضافة كتالوج المورد'));
      await tester.pumpAndSettle();

      // الكتالوج بيتحسب من أوامر المورد، مش من حقل على المنتج.
      expect(find.text('لم تتم إضافة أصناف بعد'), findsNothing);
      expect(find.text('إنشاء واعتماد الأمر'), findsOneWidget);
      expect(find.text('مصاريف الشحن'), findsOneWidget);
    });
  });

  group('المخزون', () {
    testWidgets('حوار تحويل المخزون بيعرض الفرعين', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'المخزون');

      await tester.tap(find.text('تحويل مخزون'));
      await tester.pumpAndSettle();

      // مفيش مراحل: السيرفر بينفّذ التحويل فورًا.
      expect(find.text('الفرع المُرسِل'), findsOneWidget);
      expect(find.text('الفرع المُستقبِل'), findsOneWidget);
      expect(find.text('لم تتم إضافة أصناف بعد'), findsOneWidget);
      expect(find.text('تنفيذ التحويل'), findsOneWidget);
    });

    testWidgets('شاشة الجرد بتحسب الفرق وتلوّنه', (WidgetTester tester) async {
      await _openScreen(tester, 'المخزون');

      await tester.tap(find.text('بدء جرد'));
      await tester.pumpAndSettle();

      expect(find.text('جرد المخزون'), findsOneWidget);
      expect(find.text('الكمية بالنظام'), findsOneWidget);
      expect(find.text('الكمية الفعلية'), findsOneWidget);

      // إدخال كمية فعلية أقل من النظام → عجز
      // (الحقل رقم 0 هو البحث، فأول صف في الجدول رقمه 1)
      // أول صنف في الباك اند المزيّف رصيده 80.
      await tester.enterText(find.byType(TextField).at(1), '75');
      await tester.pumpAndSettle();

      expect(find.text('-5'), findsOneWidget);
      expect(find.textContaining('صافي فرق القيمة'), findsOneWidget);
    });
  });

  group('العملاء', () {
    testWidgets('جدول العملاء وفلتر المدينين', (WidgetTester tester) async {
      await _openScreen(tester, 'العملاء');

      expect(find.text('قائمة العملاء'), findsOneWidget);
      // أسماء العملاء جاية من الباك اند المزيّف.
      expect(find.text('محمد أحمد'), findsOneWidget);
      expect(find.text('هدى إبراهيم'), findsOneWidget);

      await tester.tap(find.text('المدينون فقط'));
      await tester.pumpAndSettle();

      // عميل رصيده صفر مايظهرش
      expect(find.text('هدى إبراهيم'), findsNothing);
      expect(find.text('محمد أحمد'), findsOneWidget);
    });

    testWidgets('ملف العميل بتبويباته الثلاثة', (WidgetTester tester) async {
      await _openScreen(tester, 'العملاء');

      await tester.tap(find.text('محمد أحمد'));
      await tester.pumpAndSettle();

      expect(find.text('ملف العميل'), findsOneWidget);
      expect(find.text('الحد الائتماني'), findsOneWidget);
      expect(find.text('نقاط الولاء'), findsWidgets);

      // كشف الحساب — Timeline
      await tester.tap(find.text('كشف الحساب'));
      await tester.pumpAndSettle();
      expect(find.text('فاتورة بيع'), findsWidgets);

      // نقاط الولاء
      await tester.tap(find.text('نقاط الولاء').last);
      await tester.pumpAndSettle();
      expect(find.text('رصيد النقاط الحالي'), findsOneWidget);
      expect(find.text('سجل النقاط'), findsOneWidget);
    });
  });

  group('الموردين', () {
    testWidgets('جدول الموردين وملف المورد', (WidgetTester tester) async {
      await _openScreen(tester, 'الموردين');

      expect(find.text('قائمة الموردين'), findsOneWidget);
      expect(find.text('شركة النور للتوريدات'), findsWidgets);

      await tester.tap(find.text('شركة النور للتوريدات').first);
      await tester.pumpAndSettle();

      expect(find.text('ملف المورد'), findsOneWidget);
      expect(find.text('الرصيد المستحق للمورد'), findsOneWidget);
      expect(find.text('الأصناف الموردة'), findsWidgets);

      await tester.tap(find.text('كشف الحساب والمدفوعات').last);
      await tester.pumpAndSettle();
      expect(find.text('إجمالي المدفوع'), findsOneWidget);
    });
  });

  group('الموظفين', () {
    testWidgets('جدول الموظفين بيعرض آخر دخول', (WidgetTester tester) async {
      await _openScreen(tester, 'الموظفين');

      expect(find.text('قائمة الموظفين'), findsOneWidget);
      expect(find.text('آخر دخول'), findsOneWidget);
      expect(find.text('سارة الكاشير'), findsWidgets);
    });

    testWidgets('شاشة الصلاحيات بتبدّل الأدوار وتحفظ التغييرات', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'الموظفين');

      await tester.tap(find.text('الأدوار والصلاحيات'));
      await tester.pumpAndSettle();

      expect(find.text('صلاحيات دور: كاشير'), findsOneWidget);
      expect(find.text('يمكنه تطبيق خصم'), findsOneWidget);
      expect(find.text('كل التغييرات محفوظة'), findsOneWidget);

      // تبديل الدور
      await tester.tap(find.text('محاسب'));
      await tester.pumpAndSettle();
      expect(find.text('صلاحيات دور: محاسب'), findsOneWidget);

      // تفعيل صلاحية → الشريط السفلي بيتغير
      await tester.tap(find.text('يمكنه تطبيق خصم'));
      await tester.pumpAndSettle();
      expect(find.textContaining('تغييرات غير محفوظة'), findsOneWidget);

      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pumpAndSettle();
      expect(find.text('كل التغييرات محفوظة'), findsOneWidget);
    });
  });
}
