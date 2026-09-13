import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/mock_data/mock_data.dart';
import 'package:pos_system/core/widgets/numpad.dart';
import 'package:pos_system/features/payment/screens/payment_dialog.dart';
import 'package:pos_system/features/pos_sale/screens/pos_sale_screen.dart';
import 'package:pos_system/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_backend.dart';

/// مقاس شاشة سطح المكتب اللي النظام متصمم عليه
const Size _desktop = Size(1440, 900);

Future<void> _pumpDesktop(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = _desktop;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  // التطبيق بيبدأ على شاشة انتظار لحد ما يقرا الجلسة المحفوظة،
  // فبنستنى لحد ما يستقر على الشاشة الحقيقية.
  await tester.pumpAndSettle();
}

/// يفتح التطبيق كامل وينتقل لشاشة من القائمة الجانبية
Future<void> _openScreen(WidgetTester tester, String navLabel) async {
  await _pumpDesktop(tester, PosSystemApp(api: FakeBackend().client()));
  // أول نتيجة هي عنصر القائمة الجانبية (الـSidebar أول عنصر في الـRow)
  await tester.tap(find.text(navLabel).first);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'pos.access_token': 'fake-access',
      'pos.refresh_token': 'fake-refresh',
    });
  });

  group('الهيكل العام', () {
    testWidgets('يفتح التطبيق على شاشة الترحيب باتجاه RTL', (
      WidgetTester tester,
    ) async {
      await _pumpDesktop(tester, PosSystemApp(api: FakeBackend().client()));

      expect(find.text('أهلاً بك في POS System'), findsOneWidget);

      final Directionality directionality = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });
  });

  group('نقطة البيع', () {
    testWidgets('الضغط على منتج يضيفه للسلة ويحدّث الإجمالي', (
      WidgetTester tester,
    ) async {
      await _pumpDesktop(
        tester,
        await wrapScreen(const PosSaleScreen()),
      );

      expect(find.text('السلة فارغة'), findsOneWidget);

      await tester.tap(find.text('بيبسي كانز').first);
      await tester.pumpAndSettle();

      expect(find.text('السلة فارغة'), findsNothing);
      // سعر المنتج 10 + ضريبة 14%
      expect(find.text('11.40'), findsOneWidget);
    });

    testWidgets('حوار الدفع يفتح ويعرض أنيميشن النجاح بعد التأكيد', (
      WidgetTester tester,
    ) async {
      await _pumpDesktop(
        tester,
        await wrapScreen(const PosSaleScreen()),
      );

      await tester.tap(find.text('بيبسي كانز').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('الدفع'));
      await tester.pumpAndSettle();

      // طرق الدفع الأربعة + الـNumpad
      expect(find.text('كاش'), findsWidgets);
      expect(find.text('آجل'), findsOneWidget);
      expect(find.text('الإجمالي المطلوب'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      await tester.tap(find.text('تأكيد الدفع'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('تم الدفع بنجاح'), findsOneWidget);

      // ننتظر الأنيميشن ثم مؤقّت التأخير قبل قفل الحوار.
      // (pumpAndSettle لوحده مش بيقدّم المؤقتات لأنها مش بتجدول frames)
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      await tester.pumpAndSettle();

      // الحوار اتقفل والسلة اتفضّت
      expect(find.text('تم الدفع بنجاح'), findsNothing);
      expect(find.text('السلة فارغة'), findsOneWidget);
    });

    testWidgets('التقسيم على أكتر من طريقة دفع بيحسب المتبقي صح', (
      WidgetTester tester,
    ) async {
      await _pumpDesktop(
        tester,
        await wrapScreen(const PosSaleScreen()),
      );

      await tester.tap(find.text('بيبسي كانز').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('الدفع'));
      await tester.pumpAndSettle();

      // ندخل مبلغ أقل من الإجمالي (10) فيتفعّل زر التقسيم.
      // نحصر البحث جوه الحوار لأن شاشة الكاشير لسه موجودة تحته.
      Finder key(String label) => find.descendant(
            of: find.byType(PaymentDialog),
            matching: find.text(label),
          );

      // أزرار الأرقام تحديدًا — خانة المبلغ فيها نص مبدئي بنفس الأرقام.
      Finder numpadKey(String label) => find.descendant(
            of: find.byType(Numpad),
            matching: find.text(label),
          );

      await tester.tap(numpadKey('1'));
      await tester.pump();
      await tester.tap(numpadKey('0'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('إضافة طريقة دفع أخرى'));
      await tester.pumpAndSettle();

      expect(find.text('الدفعات المسجّلة'), findsOneWidget);
      // الدفعة الأولى اتسجّلت بـ10 والمتبقي اتحسب
      expect(key('10.00 ج.م'), findsOneWidget);
    });
  });

  group('المنتجات', () {
    testWidgets('الجدول بيظهر والتبويبات بتفلتر', (WidgetTester tester) async {
      await _openScreen(tester, 'المنتجات');

      expect(find.text('SKU'), findsOneWidget);
      // أسماء المنتجات جاية من الباك اند المزيّف.
      expect(find.text('بيبسي كانز'), findsOneWidget);

      await tester.tap(find.text('غير نشطة'));
      await tester.pumpAndSettle();

      expect(find.text('شيبسي جبنة'), findsOneWidget);
      expect(find.text('بيبسي كانز'), findsNothing);
      expect(find.text('غير نشط'), findsOneWidget);
    });

    testWidgets('الفرز بالضغط على عمود الكمية شغال', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'المنتجات');

      await tester.tap(find.text('الكمية'));
      await tester.pumpAndSettle();

      // أقل كمية (منتج نافد) المفروض تبقى أول صف
      expect(find.text('نفد المخزون'), findsWidgets);
    });

    testWidgets('زر إضافة منتج بيفتح شاشة النموذج بتبويباتها', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'المنتجات');

      await tester.tap(find.text('إضافة منتج'));
      await tester.pumpAndSettle();

      expect(find.text('إضافة منتج جديد'), findsOneWidget);
      expect(find.text('بيانات أساسية'), findsOneWidget);
      expect(find.text('الباركود'), findsOneWidget);
      // الشريط السفلي الثابت
      expect(find.text('حفظ المنتج'), findsOneWidget);
    });

    testWidgets('هامش الربح بيتحسب لحظيًا في تبويب التسعير', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'المنتجات');
      await tester.tap(find.text('إضافة منتج'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('التسعير'));
      await tester.pumpAndSettle();

      final Finder cost = find.ancestor(
        of: find.text('سعر التكلفة'),
        matching: find.byType(Column),
      );
      expect(cost, findsWidgets);

      // تكلفة 60 وسعر بيع 100 → هامش 40%
      await tester.enterText(find.byType(TextField).at(0), '60');
      await tester.enterText(find.byType(TextField).at(1), '100');
      await tester.pumpAndSettle();

      expect(find.text('40.0%'), findsOneWidget);
      expect(find.text('الربح على القطعة: 40.00 ج.م'), findsOneWidget);
    });
  });

  group('المخزون', () {
    testWidgets('البطاقات الإحصائية والجدول بيظهروا', (
      WidgetTester tester,
    ) async {
      await _openScreen(tester, 'المخزون');

      expect(find.text('إجمالي قيمة المخزون'), findsOneWidget);
      expect(find.text('منتجات نافدة'), findsOneWidget);
      expect(find.text('قاربت على انتهاء الصلاحية'), findsOneWidget);
      expect(find.text('تحويل مخزون'), findsOneWidget);
      expect(find.text('بدء جرد'), findsOneWidget);

      // أعمدة الجدول
      expect(find.text('الكمية الفعلية'), findsOneWidget);
      expect(find.text('المحجوزة'), findsOneWidget);
      expect(find.text('المتاحة'), findsOneWidget);
    });

    testWidgets('فلتر الفرع بيقلّل عدد السجلات', (WidgetTester tester) async {
      await _openScreen(tester, 'المخزون');

      // كل الفروع = عدد المنتجات × عدد الفروع
      expect(
        find.text('(${MockData.stockRecords.length} سجل)'),
        findsOneWidget,
      );

      await tester.tap(find.text('كل الفروع والمخازن'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(MockData.branches[1].name).last);
      await tester.pumpAndSettle();

      expect(
        find.text('(${MockData.products.length} سجل)'),
        findsOneWidget,
      );
      expect(find.text('كل الفروع والمخازن'), findsNothing);
    });
  });
}
