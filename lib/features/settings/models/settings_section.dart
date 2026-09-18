import 'package:flutter/material.dart';

/// أقسام الإعدادات في القائمة الجانبية الفرعية.
enum SettingsSection {
  general,
  taxes,
  printing,
  devices,
  notifications,
}

extension SettingsSectionInfo on SettingsSection {
  String get label => switch (this) {
        SettingsSection.general => 'عام',
        SettingsSection.taxes => 'الضرائب',
        SettingsSection.printing => 'الطباعة والإيصالات',
        SettingsSection.devices => 'الأجهزة المتصلة',
        SettingsSection.notifications => 'الإشعارات',
      };

  String get description => switch (this) {
        SettingsSection.general => 'اسم المتجر والعملة واللغة',
        SettingsSection.taxes => 'نسب الضريبة وطريقة احتسابها',
        SettingsSection.printing => 'شكل الإيصال وبيانات الطباعة',
        SettingsSection.devices => 'الطابعات والأدراج والقارئات',
        SettingsSection.notifications => 'تنبيهات المخزون والمبيعات',
      };

  IconData get icon => switch (this) {
        SettingsSection.general => Icons.tune_rounded,
        SettingsSection.taxes => Icons.percent_rounded,
        SettingsSection.printing => Icons.print_outlined,
        SettingsSection.devices => Icons.devices_other_rounded,
        SettingsSection.notifications => Icons.notifications_none_rounded,
      };
}
