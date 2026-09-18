import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/widgets/app_form_field.dart';
import 'package:pos_system/features/product_profile/widgets/product_branches_tab.dart';
import 'package:pos_system/features/product_profile/widgets/product_details_tab.dart';
import 'package:pos_system/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_backend.dart';

const Size _desktop = Size(1600, 950);

/// بيرجّع الباك اند المزيّف عشان الاختبار يقدر يتأكد من اللي اتحفظ فيه.
Future<FakeBackend> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = _desktop;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final FakeBackend backend = FakeBackend();
  await tester.pumpWidget(PosSystemApp(api: backend.client()));
  await tester.pumpAndSettle();

  return backend;
}

Future<FakeBackend> _openScreen(WidgetTester tester, String navLabel) async {
  final FakeBackend backend = await _pumpApp(tester);
  final Finder item = find.text(navLabel).first;
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();

  return backend;
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

  testWidgets('الضغط على منتج بيفتح تفاصيله ويعدّل سعره من جوه', (
    WidgetTester tester,
  ) async {
    final FakeBackend backend = await _openScreen(tester, 'المنتجات');

    await tester.tap(find.text('بيبسي كانز'));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل المنتج'), findsOneWidget);
    expect(find.text('البيانات'), findsOneWidget);
    expect(find.text('الأرصدة'), findsOneWidget);
    expect(find.text('الحركات'), findsOneWidget);

    // شريط الحفظ مبيظهرش غير لما يبقى فيه تعديل فعلي.
    expect(find.text('حفظ التعديلات'), findsNothing);

    // «سعر البيع» مكتوب في بطاقة الملخّص كمان، فبندوّر على الحقل نفسه.
    await tester.enterText(
      find.descendant(
        of: find.byWidgetPredicate(
          (Widget w) => w is AppFormField && w.label == 'سعر البيع',
        ),
        matching: find.byType(TextField),
      ),
      '30',
    );
    await tester.pumpAndSettle();

    // شريط الحفظ تحت خالص في التبويب، فلازم ننزّله عشان يتبني.
    await tester.scrollUntilVisible(
      find.text('حفظ التعديلات'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ProductDetailsTab),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('فيه تعديلات لسه ماتحفظتش'), findsOneWidget);

    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    expect(find.text('اتحفظت تعديلات المنتج'), findsOneWidget);
    expect(backend.products.first['price'], 30);
  });

  testWidgets('تفاصيل المنتج بتعرض أرصدة الفروع وحركات المخزون', (
    WidgetTester tester,
  ) async {
    await _openScreen(tester, 'المنتجات');

    await tester.tap(find.text('بيبسي كانز'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الأرصدة'));
    await tester.pumpAndSettle();

    // اسم الفرع بيبان في القائمة الجانبية كمان، فبندوّر عليه جوه التبويب.
    expect(
      find.descendant(
        of: find.byType(ProductBranchesTab),
        matching: find.text('الفرع الرئيسي'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('الحركات'));
    await tester.pumpAndSettle();
    expect(find.text('رصيد افتتاحي'), findsOneWidget);
  });
}
