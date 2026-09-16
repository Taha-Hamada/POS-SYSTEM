import 'package:flutter/material.dart';

/// أدوار المستخدمين زي ما الباك اند بيعرّفها.
///
/// الأدوار ثابتة على السيرفر (مش بتتضاف من الشاشة)، والمتغيّر هو باقة
/// صلاحيات كل دور، فالاسم والوصف والأيقونة متعرّفين هنا مرة واحدة.
enum UserRole {
  admin(
    'admin',
    'مدير النظام',
    'صلاحيات كاملة على كل الفروع والإعدادات',
    Icons.admin_panel_settings_rounded,
  ),
  manager(
    'manager',
    'مدير فرع',
    'إدارة فرع واحد ومخزونه وموظفيه',
    Icons.store_rounded,
  ),
  cashier(
    'cashier',
    'كاشير',
    'تشغيل نقطة البيع وإصدار الفواتير',
    Icons.point_of_sale_rounded,
  ),
  accountant(
    'accountant',
    'محاسب',
    'المالية والتقارير وكشوف الحسابات',
    Icons.calculate_rounded,
  ),
  stockKeeper(
    'stock_keeper',
    'أمين مخزن',
    'المنتجات والمخزون وأوامر الشراء',
    Icons.inventory_rounded,
  );

  const UserRole(this.apiValue, this.label, this.description, this.icon);

  final String apiValue;
  final String label;
  final String description;
  final IconData icon;

  static UserRole? fromApi(String? value) {
    for (final UserRole role in values) {
      if (role.apiValue == value) return role;
    }
    return null;
  }

  /// اسم الدور للعرض، والقيمة الخام لو دور جديد الفرونت لسه مايعرفوش.
  static String labelFor(String value) => fromApi(value)?.label ?? value;
}
