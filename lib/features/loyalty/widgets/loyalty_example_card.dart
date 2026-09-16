import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/loyalty_controller.dart';

/// مثال حي بيتحدّث لحظيًا مع تغيير آلية الكسب.
class LoyaltyExampleCard extends StatelessWidget {
  const LoyaltyExampleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final LoyaltyController loyalty = context.watch<LoyaltyController>();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'مثال',
            style: AppText.label.copyWith(
              fontSize: 11,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'فاتورة ${Fmt.money(LoyaltyController.exampleInvoice)} = '
            '${Fmt.count(loyalty.examplePoints)} نقطة',
            style: AppText.bodyMedium.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 2),
          Text(
            'تعادل ${Fmt.money(loyalty.exampleDiscount)} عند الاستبدال',
            style: AppText.caption.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
