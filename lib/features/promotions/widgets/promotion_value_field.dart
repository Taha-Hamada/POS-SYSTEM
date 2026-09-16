import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/models/promotion.dart';
import '../../../core/widgets/app_form_field.dart';
import '../../../theme/app_theme.dart';
import '../controllers/promotion_form_controller.dart';

/// حقول قيمة العرض — بتتغيّر حسب نوعه.
class PromotionValueField extends StatelessWidget {
  const PromotionValueField({super.key});

  static final List<TextInputFormatter> _decimal = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];

  static final List<TextInputFormatter> _digits = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
  ];

  @override
  Widget build(BuildContext context) {
    final PromotionFormController form = context
        .watch<PromotionFormController>();

    final Widget percent = AppFormField(
      label: 'نسبة الخصم',
      controller: form.percentController,
      hint: 'مثال: 15',
      required: true,
      suffixText: '%',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: _decimal,
      onChanged: form.fieldChanged,
    );

    return switch (form.type) {
      PromotionType.percentage => percent,
      PromotionType.quantityDiscount => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: percent),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: AppFormField(
              label: 'من كمية',
              controller: form.minQuantityController,
              hint: '10',
              required: true,
              suffixText: 'قطعة',
              keyboardType: TextInputType.number,
              inputFormatters: _digits,
              onChanged: form.fieldChanged,
            ),
          ),
        ],
      ),
      PromotionType.buyXGetY => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: AppFormField(
              label: 'اشترِ',
              controller: form.buyController,
              hint: '2',
              required: true,
              suffixText: 'قطعة',
              keyboardType: TextInputType.number,
              inputFormatters: _digits,
              onChanged: form.fieldChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: AppFormField(
              label: 'واحصل مجانًا على',
              controller: form.getController,
              hint: '1',
              required: true,
              suffixText: 'قطعة',
              keyboardType: TextInputType.number,
              inputFormatters: _digits,
              onChanged: form.fieldChanged,
            ),
          ),
        ],
      ),
    };
  }
}
