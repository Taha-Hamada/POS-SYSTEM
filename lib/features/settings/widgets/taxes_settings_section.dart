import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_form_field.dart';
import '../../../theme/app_theme.dart';
import '../controllers/settings_controller.dart';
import 'setting_switch.dart';
import 'settings_panel.dart';
import 'tax_example_card.dart';

/// قسم إعدادات الضرائب.
class TaxesSettingsSection extends StatelessWidget {
  const TaxesSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final bool editable = settings.canEdit;

    return SettingsPanel(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: AppFormField(
                label: 'نسبة الضريبة الأساسية',
                controller: settings.taxRateController,
                suffixText: '%',
                prefixIcon: Icons.percent_rounded,
                enabled: editable,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: settings.fieldChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppFormField(
                label: 'الرقم الضريبي',
                hint: '000-000-000',
                prefixIcon: Icons.badge_outlined,
                controller: settings.taxNumberController,
                enabled: editable,
                onChanged: settings.fieldChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SettingSwitch(
          title: 'الأسعار شاملة الضريبة',
          subtitle: 'السعر المعروض للعميل بيشمل الضريبة',
          value: settings.taxIncluded,
          onChanged: editable ? settings.setTaxIncluded : (_) {},
          isLast: true,
        ),
        const SizedBox(height: AppSpacing.xl),
        const TaxExampleCard(),
      ],
    );
  }
}
