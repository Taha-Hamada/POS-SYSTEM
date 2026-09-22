import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_form_field.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/product_form_controller.dart';
import 'form_hint_row.dart';
import 'product_form_tab_card.dart';
import 'profit_margin_card.dart';

/// التبويب التاني: سعر التكلفة وسعر البيع وهامش الربح.
class PricingTab extends StatelessWidget {
  const PricingTab({super.key});

  static final List<TextInputFormatter> _decimalOnly = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];

  @override
  Widget build(BuildContext context) {
    final ProductFormController form = context.read<ProductFormController>();

    return ProductFormTabCard(
      children: <Widget>[
        const FormSectionTitle(
          title: 'التسعير وهامش الربح',
          subtitle: 'سعر التكلفة وسعر البيع — الهامش بيتحسب تلقائيًا',
          icon: Icons.sell_outlined,
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: AppFormField(
                label: 'سعر التكلفة',
                controller: form.costController,
                hint: '0.00',
                suffixText: Fmt.currencySymbol,
                prefixIcon: Icons.shopping_bag_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: _decimalOnly,
                onChanged: form.fieldChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: AppFormField(
                label: 'سعر البيع بالقطعة',
                controller: form.priceController,
                hint: '0.00',
                required: true,
                suffixText: Fmt.currencySymbol,
                prefixIcon: Icons.local_offer_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: _decimalOnly,
                onChanged: form.fieldChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: AppFormField(
                label: 'سعر البيع بالكرتونة',
                controller: form.cartonPriceController,
                hint: '0.00',
                suffixText: Fmt.currencySymbol,
                prefixIcon: Icons.inventory_2_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: _decimalOnly,
                onChanged: form.fieldChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: AppFormField(
                label: 'عدد القطع في الكرتونة',
                controller: form.piecesPerCartonController,
                hint: '12',
                suffixText: 'قطعة',
                prefixIcon: Icons.widgets_outlined,
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
        const ProfitMarginCard(),
        const SizedBox(height: AppSpacing.lg),
        const FormHintRow(
          icon: Icons.info_outline_rounded,
          text: 'هامش الربح = (سعر البيع − سعر التكلفة) ÷ سعر البيع × 100',
        ),
      ],
    );
  }
}
