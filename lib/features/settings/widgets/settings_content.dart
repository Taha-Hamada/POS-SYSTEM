import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/settings_controller.dart';
import '../models/settings_section.dart';
import 'devices_settings_section.dart';
import 'general_settings_section.dart';
import 'notifications_settings_section.dart';
import 'printing_settings_section.dart';
import 'taxes_settings_section.dart';

/// محتوى القسم المختار — بيتبدّل بأنيميشن Fade.
class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: settings.fadeController,
        curve: Curves.easeOut,
      ),
      child: switch (settings.section) {
        SettingsSection.general => const GeneralSettingsSection(),
        SettingsSection.taxes => const TaxesSettingsSection(),
        SettingsSection.printing => const PrintingSettingsSection(),
        SettingsSection.devices => const DevicesSettingsSection(),
        SettingsSection.notifications => const NotificationsSettingsSection(),
      },
    );
  }
}
