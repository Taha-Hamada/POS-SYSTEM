import 'package:flutter/material.dart';

/// صلاحية واحدة بالاسم اللي بيظهر للمدير.
class PermissionDef {
  const PermissionDef(this.value, this.label, this.description);

  /// القيمة زي ما السيرفر بيعرفها: "مورد:إجراء".
  final String value;
  final String label;
  final String description;
}

/// قسم صلاحيات في شاشة الأدوار.
class PermissionGroupDef {
  const PermissionGroupDef({
    required this.title,
    required this.icon,
    required this.permissions,
  });

  final String title;
  final IconData icon;
  final List<PermissionDef> permissions;
}

/// أسماء صلاحيات السيرفر بالعربي ومتقسّمة حسب شغل كل قسم.
///
/// السيرفر بيبعت القيم الخام بس، فالترجمة والتقسيم هنا. أي صلاحية جديدة
/// على السيرفر ومش مكتوبة هنا بتظهر في قسم «أخرى» بدل ما تستخبى.
const List<PermissionGroupDef> kPermissionGroups = <PermissionGroupDef>[
  PermissionGroupDef(
    title: 'المبيعات',
    icon: Icons.point_of_sale_rounded,
    permissions: <PermissionDef>[
      PermissionDef(
        'invoice:create',
        'يمكنه فتح شاشة نقطة البيع',
        'الدخول للكاشير وتسجيل الفواتير',
      ),
      PermissionDef(
        'invoice:view',
        'يمكنه عرض الفواتير',
        'الاطلاع على الفواتير السابقة والمعلّقة',
      ),
      PermissionDef(
        'invoice:discount',
        'يمكنه تطبيق خصم',
        'خصم يدوي على الفاتورة أو الصنف',
      ),
      PermissionDef(
        'invoice:void',
        'يمكنه إلغاء فاتورة',
        'إلغاء فاتورة بعد إصدارها',
      ),
      PermissionDef(
        'return:view',
        'يمكنه عرض المرتجعات',
        'الاطلاع على المرتجعات السابقة',
      ),
      PermissionDef(
        'return:manage',
        'يمكنه عمل مرتجعات',
        'إرجاع أصناف واسترداد المبالغ',
      ),
      PermissionDef(
        'promotion:view',
        'يمكنه عرض العروض',
        'الاطلاع على العروض والخصومات',
      ),
      PermissionDef(
        'promotion:manage',
        'يمكنه إدارة العروض',
        'إنشاء وتعديل وإيقاف العروض',
      ),
    ],
  ),
  PermissionGroupDef(
    title: 'العملاء والموردين',
    icon: Icons.people_alt_rounded,
    permissions: <PermissionDef>[
      PermissionDef(
        'customer:view',
        'يمكنه عرض العملاء',
        'بيانات العملاء وكشوف حساباتهم',
      ),
      PermissionDef(
        'customer:manage',
        'يمكنه إدارة العملاء',
        'إضافة عملاء وتحصيل المديونيات واستبدال النقاط',
      ),
      PermissionDef(
        'supplier:view',
        'يمكنه عرض الموردين',
        'بيانات الموردين وأرصدتهم',
      ),
      PermissionDef(
        'supplier:manage',
        'يمكنه إدارة الموردين',
        'إضافة وتعديل الموردين وتسجيل المدفوعات',
      ),
    ],
  ),
  PermissionGroupDef(
    title: 'المخزون',
    icon: Icons.warehouse_rounded,
    permissions: <PermissionDef>[
      PermissionDef(
        'product:view',
        'يمكنه عرض المنتجات',
        'الاطلاع على الأصناف والأسعار',
      ),
      PermissionDef(
        'product:manage',
        'يمكنه إدارة المنتجات',
        'إضافة وتعديل وإيقاف المنتجات',
      ),
      PermissionDef('category:view', 'يمكنه عرض الأقسام', 'تصنيفات المنتجات'),
      PermissionDef(
        'category:manage',
        'يمكنه إدارة الأقسام',
        'إضافة وتعديل تصنيفات المنتجات',
      ),
      PermissionDef(
        'inventory:view',
        'يمكنه عرض المخزون',
        'الاطلاع على الأرصدة والحركات',
      ),
      PermissionDef(
        'inventory:adjust',
        'يمكنه تعديل الكميات والجرد',
        'التسويات المباشرة وترحيل فروقات الجرد',
      ),
      PermissionDef(
        'inventory:transfer',
        'يمكنه تحويل مخزون بين الفروع',
        'نقل أصناف من فرع لفرع',
      ),
    ],
  ),
  PermissionGroupDef(
    title: 'المشتريات',
    icon: Icons.shopping_cart_rounded,
    permissions: <PermissionDef>[
      PermissionDef(
        'purchase:view',
        'يمكنه عرض أوامر الشراء',
        'الاطلاع على أوامر الشراء وحالتها',
      ),
      PermissionDef(
        'purchase:manage',
        'يمكنه إدارة أوامر الشراء',
        'إنشاء واعتماد واستلام أوامر الشراء',
      ),
    ],
  ),
  PermissionGroupDef(
    title: 'المالية',
    icon: Icons.account_balance_wallet_rounded,
    permissions: <PermissionDef>[
      PermissionDef(
        'shift:view',
        'يمكنه عرض الورديات',
        'الاطلاع على الورديات وأرقام الدرج',
      ),
      PermissionDef(
        'shift:manage',
        'يمكنه فتح وإغلاق الورديات',
        'إدارة درج الكاش والعُهد',
      ),
      PermissionDef(
        'expense:view',
        'يمكنه عرض المصروفات',
        'الاطلاع على مصروفات التشغيل',
      ),
      PermissionDef(
        'expense:manage',
        'يمكنه تسجيل المصروفات',
        'إضافة مصروفات التشغيل',
      ),
      PermissionDef(
        'expense:approve',
        'يمكنه اعتماد المصروفات',
        'قبول أو رفض المصروفات المعلّقة',
      ),
      PermissionDef(
        'report:view',
        'يمكنه عرض التقارير',
        'تقارير المبيعات والأرباح والمخزون',
      ),
    ],
  ),
  PermissionGroupDef(
    title: 'الإدارة',
    icon: Icons.settings_rounded,
    permissions: <PermissionDef>[
      PermissionDef(
        'branch:view',
        'يمكنه عرض الفروع',
        'الاطلاع على الفروع وفتحها وقفلها',
      ),
      PermissionDef(
        'branch:manage',
        'يمكنه إدارة الفروع',
        'إضافة فروع وتعديلها وتعطيلها',
      ),
      PermissionDef(
        'user:view',
        'يمكنه عرض الموظفين',
        'قائمة الموظفين وأدوارهم',
      ),
      PermissionDef(
        'user:manage',
        'يمكنه إدارة الموظفين والصلاحيات',
        'إضافة موظفين وتعديل صلاحيات الأدوار',
      ),
      PermissionDef(
        'settings:manage',
        'يمكنه تغيير إعدادات النظام',
        'الضرائب والعملة وشكل الفاتورة',
      ),
    ],
  ),
];

/// الأقسام بالصلاحيات اللي السيرفر بيعرفها فعلًا.
///
/// الصلاحيات المكتوبة هنا ومش على السيرفر بتتشال عشان متتبعتش وتترفض،
/// واللي على السيرفر ومش مكتوبة بتتجمع في قسم «أخرى».
List<PermissionGroupDef> permissionGroupsFor(List<String> serverPermissions) {
  final Set<String> known = serverPermissions.toSet();
  final Set<String> listed = <String>{};

  final List<PermissionGroupDef> groups = <PermissionGroupDef>[];

  for (final PermissionGroupDef group in kPermissionGroups) {
    final List<PermissionDef> present = group.permissions
        .where((PermissionDef p) => known.contains(p.value))
        .toList(growable: false);

    listed.addAll(group.permissions.map((PermissionDef p) => p.value));
    if (present.isEmpty) continue;

    groups.add(
      PermissionGroupDef(
        title: group.title,
        icon: group.icon,
        permissions: present,
      ),
    );
  }

  final List<PermissionDef> others = serverPermissions
      .where((String p) => !listed.contains(p))
      .map((String p) => PermissionDef(p, p, 'صلاحية جديدة من السيرفر'))
      .toList(growable: false);

  if (others.isNotEmpty) {
    groups.add(
      PermissionGroupDef(
        title: 'أخرى',
        icon: Icons.more_horiz_rounded,
        permissions: others,
      ),
    );
  }

  return groups;
}
