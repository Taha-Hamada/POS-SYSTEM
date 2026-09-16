import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/promotion.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../theme/app_theme.dart';
import '../controllers/promotion_form_controller.dart';
import '../models/promotion_type_color.dart';

/// اختيار نوع العرض في الفورم.
class PromotionTypeField extends StatelessWidget {
  const PromotionTypeField({super.key});

  @override
  Widget build(BuildContext context) {
    final PromotionFormController form = context
        .watch<PromotionFormController>();

    return LabeledField(
      label: 'نوع العرض',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppDropdown<PromotionType>(
            value: form.type,
            width: double.infinity,
            height: 48,
            onChanged: form.setType,
            items: <AppDropdownItem<PromotionType>>[
              for (final PromotionType t in PromotionType.values)
                AppDropdownItem<PromotionType>(
                  value: t,
                  label: t.label,
                  icon: t.icon,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(form.type.hint, style: AppText.caption.copyWith(fontSize: 11.5)),
        ],
      ),
    );
  }
}
