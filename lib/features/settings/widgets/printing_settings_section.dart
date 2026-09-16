import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/printing/print_preferences.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_form_field.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../theme/app_theme.dart';
import '../controllers/settings_controller.dart';
import 'receipt_preview.dart';
import 'settings_panel.dart';

/// قسم إعدادات الطباعة والإيصالات.
class PrintingSettingsSection extends StatelessWidget {
  const PrintingSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final bool editable = settings.canEdit;

    return SettingsPanel(
      children: <Widget>[
        const _AutoPrintSwitch(),
        const SizedBox(height: AppSpacing.lg),
        AppFormField(
          label: 'نص أسفل الإيصال',
          controller: settings.footerNoteController,
          maxLines: 2,
          hint: 'رسالة شكر أو سياسة الاسترجاع',
          enabled: editable,
          onChanged: settings.fieldChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledField(
          label: 'عرض ورق الإيصال',
          child: AppDropdown<int>(
            value: settings.receiptWidth,
            width: double.infinity,
            height: 48,
            icon: Icons.straighten_rounded,
            onChanged: editable ? settings.setReceiptWidth : (_) {},
            items: <AppDropdownItem<int>>[
              for (final int w in <int>{
                ...SettingsController.receiptWidths,
                settings.receiptWidth,
              })
                AppDropdownItem<int>(value: w, label: '$w مم'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('معاينة الإيصال', style: AppText.label.copyWith(fontSize: 12.5)),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: ReceiptPreview(
            storeName: settings.storeNameController.text,
            subtitle: settings.storeAddressController.text,
            footer: settings.footerNoteController.text,
            widthMm: settings.receiptWidth,
          ),
        ),
      ],
    );
  }
}

/// الطباعة التلقائية بتتحفظ على الجهاز فورًا، مش مع زرار حفظ الإعدادات.
class _AutoPrintSwitch extends StatefulWidget {
  const _AutoPrintSwitch();

  @override
  State<_AutoPrintSwitch> createState() => _AutoPrintSwitchState();
}

class _AutoPrintSwitchState extends State<_AutoPrintSwitch> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    PrintPreferences.autoPrintReceipt().then((bool value) {
      if (mounted) setState(() => _enabled = value);
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await PrintPreferences.setAutoPrintReceipt(value);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        'طباعة الإيصال تلقائيًا بعد الدفع',
        style: AppText.bodyMedium,
      ),
      subtitle: Text(
        'إعداد خاص بالجهاز ده — فعّله على جهاز الكاشير المتوصل بالطابعة',
        style: AppText.caption,
      ),
      value: _enabled ?? false,
      onChanged: _enabled == null ? null : _toggle,
    );
  }
}
