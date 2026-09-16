import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/settings_controller.dart';
import 'setting_switch.dart';
import 'settings_panel.dart';

/// قسم التنبيهات — بيتحكم في جرس الشريط العلوي.
class NotificationsSettingsSection extends StatelessWidget {
  const NotificationsSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();

    return SettingsPanel(
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.notifications_active_outlined,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'التنبيهات بتظهر في جرس الشريط العلوي لكل المستخدمين، '
                'وبتتحفظ على السيرفر. مفيش إيميل أو رسايل لسه.',
                style: AppText.caption.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingSwitch(
          title: 'تنبيه نقص المخزون',
          subtitle: 'الأصناف اللي وصلت لنقطة إعادة الطلب أو خلصت',
          value: settings.notifyLowStock,
          onChanged: settings.canEdit ? settings.setNotifyLowStock : (_) {},
        ),
        SettingSwitch(
          title: 'تنبيه قرب انتهاء الصلاحية',
          subtitle: 'المنتجات اللي صلاحيتها بتخلص خلال شهر',
          value: settings.notifyExpiry,
          onChanged: settings.canEdit ? settings.setNotifyExpiry : (_) {},
          isLast: true,
        ),
      ],
    );
  }
}
