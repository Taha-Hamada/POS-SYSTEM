import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/core/widgets/placeholder_screen.dart';
import 'package:pos_system/widgets/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_backend.dart';

const Size _desktop = Size(1600, 950);

void main() {
  setUp(() {
    // الشاشات بقت بتقرأ من الـ API، فبنشغّلها على باك اند مزيّف
    // وبجلسة محفوظة عشان التطبيق يعدّي شاشة الدخول.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'pos.access_token': 'fake-access',
      'pos.refresh_token': 'fake-refresh',
    });
  });

  testWidgets('كل عنصر في القائمة الجانبية بيفتح شاشته الحقيقية', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = _desktop;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(PosSystemApp(api: FakeBackend().client()));
    await tester.pumpAndSettle();

    expect(kNavItems.length, 17);

    for (final NavItem item in kNavItems) {
      final Finder navItem = find.text(item.label).first;
      await tester.ensureVisible(navItem);
      await tester.pumpAndSettle();
      await tester.tap(navItem);
      await tester.pumpAndSettle();

      // عنوان الشاشة بيظهر في الشريط العلوي
      expect(
        find.text(item.label),
        findsWidgets,
        reason: 'المسار ${item.route} مافتحش',
      );

      // مفيش أي شاشة لسه Placeholder
      expect(
        find.byType(PlaceholderScreen),
        findsNothing,
        reason: 'المسار ${item.route} لسه Placeholder',
      );
    }
  });

  testWidgets('المسارات الفرعية بترجع لشاشاتها الأصلية', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = _desktop;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(PosSystemApp(api: FakeBackend().client()));
    await tester.pumpAndSettle();

    // المنتجات ← إضافة منتج ← رجوع
    final Finder products = find.text('المنتجات').first;
    await tester.ensureVisible(products);
    await tester.pumpAndSettle();
    await tester.tap(products);
    await tester.pumpAndSettle();

    await tester.tap(find.text('إضافة منتج'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة منتج جديد'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة منتج جديد'), findsNothing);
    expect(find.text('SKU'), findsOneWidget);
  });

  testWidgets('شاشة التقارير بتبدّل بين أنواع التقارير', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = _desktop;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(PosSystemApp(api: FakeBackend().client()));
    await tester.pumpAndSettle();

    final Finder reports = find.text('التقارير').first;
    await tester.ensureVisible(reports);
    await tester.pumpAndSettle();
    await tester.tap(reports);
    await tester.pumpAndSettle();

    // تقرير المبيعات هو الافتراضي
    expect(find.text('التفاصيل اليومية'), findsOneWidget);
    expect(find.text('حركة المبيعات'), findsOneWidget);

    // الأرباح
    await tester.tap(find.text('تقرير الأرباح').first);
    await tester.pumpAndSettle();
    expect(find.text('الربحية حسب الفئة'), findsOneWidget);
    expect(find.text('تكلفة البضاعة المباعة'), findsOneWidget);

    // الضرائب
    await tester.tap(find.text('التقرير الضريبي').first);
    await tester.pumpAndSettle();
    expect(find.text('الإقرار الضريبي الشهري'), findsOneWidget);
    expect(find.text('صافي المستحق للمصلحة'), findsOneWidget);

    // المخزون ("قيمة المخزون حسب الفئة" بتظهر كمان كوصف في قائمة التقارير)
    await tester.tap(find.text('تقرير المخزون').first);
    await tester.pumpAndSettle();
    expect(find.text('قيمة المخزون حسب الفئة'), findsWidgets);
    expect(find.text('الربح المتوقع'), findsWidgets);

    // أداء الموظفين
    await tester.tap(find.text('أداء الموظفين').first);
    await tester.pumpAndSettle();
    expect(find.text('أعلى موظف مبيعًا'), findsOneWidget);

    // تغيير الفترة
    await tester.tap(find.text('آخر 7 أيام').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('آخر 7 أيام'), findsWidgets);
  });
}
