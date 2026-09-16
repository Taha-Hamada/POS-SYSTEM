import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_form_field.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../theme/app_theme.dart';
import '../controllers/settings_controller.dart';
import 'setting_switch.dart';
import 'settings_panel.dart';

/// قسم الإعدادات العامة: بيانات المتجر والعملة وسياسات البيع.
class GeneralSettingsSection extends StatelessWidget {
  const GeneralSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final bool editable = settings.canEdit;

    // عملة مخزّنة مش في القايمة بتتعرض بكودها بدل ما تختفي.
    final Map<String, String> currencies = <String, String>{
      ...SettingsController.currencies,
      if (!SettingsController.currencies.containsKey(settings.currency))
        settings.currency: settings.currency,
    };

    return SettingsPanel(
      children: <Widget>[
        AppFormField(
          label: 'اسم المتجر',
          controller: settings.storeNameController,
          hint: 'الاسم اللي هيظهر على الفواتير',
          required: true,
          enabled: editable,
          onChanged: settings.fieldChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: AppFormField(
                label: 'العنوان',
                controller: settings.storeAddressController,
                hint: 'بيظهر أعلى الإيصال',
                prefixIcon: Icons.location_on_outlined,
                enabled: editable,
                onChanged: settings.fieldChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppFormField(
                label: 'التليفون',
                controller: settings.storePhoneController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                enabled: editable,
                onChanged: settings.fieldChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledField(
          label: 'العملة',
          child: AppDropdown<String>(
            value: settings.currency,
            width: double.infinity,
            height: 48,
            icon: Icons.payments_outlined,
            onChanged: editable ? settings.setCurrency : (_) {},
            items: <AppDropdownItem<String>>[
              for (final MapEntry<String, String> c in currencies.entries)
                AppDropdownItem<String>(value: c.key, label: c.value),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('سياسات البيع', style: AppText.label.copyWith(fontSize: 12.5)),
        const SizedBox(height: AppSpacing.sm),
        SettingSwitch(
          title: 'لازم وردية مفتوحة قبل البيع',
          subtitle: 'الكاشير مايقدرش يبيع غير بعد ما يفتح الدرج',
          value: settings.requireOpenShift,
          onChanged: editable ? settings.setRequireOpenShift : _readOnly,
        ),
        SettingSwitch(
          title: 'البيع الآجل على عميل مسجّل بس',
          subtitle: 'مينفعش تبيع آجل من غير ما تختار العميل',
          value: settings.requireCustomerForCredit,
          onChanged: editable
              ? settings.setRequireCustomerForCredit
              : _readOnly,
        ),
        SettingSwitch(
          title: 'السماح بالبيع بالسالب',
          subtitle: 'البيع يكمل حتى لو رصيد الصنف مايكفيش',
          value: settings.allowNegativeStock,
          onChanged: editable ? settings.setAllowNegativeStock : _readOnly,
          isLast: true,
        ),
      ],
    );
  }
}

/// المستخدم مالوش صلاحية تعديل، فالمفاتيح بتفضل على قيمتها.
void _readOnly(bool _) {}
