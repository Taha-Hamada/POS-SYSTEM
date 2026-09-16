import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_form_field.dart';
import '../../../theme/app_theme.dart';
import '../controllers/product_form_controller.dart';
import 'labeled_dropdown.dart';
import 'product_form_tab_card.dart';
import 'reorder_hint_card.dart';

/// التبويب الرابع: الوحدة ونقطة إعادة الطلب والرصيد الافتتاحي.
class StockTab extends StatelessWidget {
  const StockTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductFormController form = context.watch<ProductFormController>();

    return ProductFormTabCard(
      children: <Widget>[
        const FormSectionTitle(
          title: 'المخزون والوحدات',
          subtitle: 'وحدة القياس ونقطة إعادة الطلب والرصيد الافتتاحي',
          icon: Icons.warehouse_outlined,
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: LabeledDropdown<String>(
                label: 'الوحدة الأساسية',
                value: form.unit,
                icon: Icons.straighten_rounded,
                onChanged: form.setUnit,
                items: <AppDropdownItem<String>>[
                  for (final String u in form.unitOptions)
                    AppDropdownItem<String>(value: u, label: u),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: AppFormField(
                label: 'نقطة إعادة الطلب',
                controller: form.reorderController,
                hint: '10',
                suffixText: form.unit,
                prefixIcon: Icons.notifications_active_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: form.fieldChanged,
              ),
            ),
            // الرصيد الافتتاحي بيتسجل مرة واحدة مع الإضافة، وبعدها بيتغير
            // بحركات المخزون بس عشان التاريخ يفضل مظبوط.
            if (!form.isEditing) const SizedBox(width: AppSpacing.xl),
            if (!form.isEditing)
              Expanded(
                child: AppFormField(
                  label: 'المخزون الابتدائي',
                  controller: form.openingStockController,
                  hint: '0',
                  suffixText: form.unit,
                  prefixIcon: Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: form.fieldChanged,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const ReorderHintCard(),
      ],
    );
  }
}
