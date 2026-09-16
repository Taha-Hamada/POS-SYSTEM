import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/product_form_controller.dart';

/// بطاقة هامش الربح — بتتحدّث لحظيًا مع سعر التكلفة والبيع.
class ProfitMarginCard extends StatelessWidget {
  const ProfitMarginCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductFormController form = context.watch<ProductFormController>();
    final bool hasValues = form.hasPricing;
    final bool isLoss = form.isLoss;

    final Color tone = isLoss ? AppColors.danger : AppColors.success;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: !hasValues
            ? AppColors.surfaceAlt
            : isLoss
            ? AppColors.dangerSoft
            : AppColors.successSoft,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: !hasValues ? AppColors.border : tone.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: !hasValues
                  ? AppColors.border
                  : tone.withValues(alpha: 0.14),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(
              isLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
              size: 22,
              color: !hasValues ? AppColors.textMuted : tone,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  isLoss ? 'تبيع بخسارة!' : 'هامش الربح',
                  style: AppText.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  hasValues
                      ? 'الربح على القطعة: ${Fmt.money(form.profit)}'
                      : 'أدخل سعر التكلفة وسعر البيع لحساب الهامش',
                  style: AppText.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            hasValues ? Fmt.percent(form.margin) : '—',
            style: AppText.amountHero.copyWith(
              fontSize: 34,
              color: !hasValues ? AppColors.textMuted : tone,
            ),
          ),
        ],
      ),
    );
  }
}
