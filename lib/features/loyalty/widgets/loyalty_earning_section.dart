import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/loyalty_controller.dart';
import 'loyalty_example_card.dart';
import 'loyalty_rate_field.dart';

/// قسم إعداد آلية كسب النقاط وقيمة استبدالها.
class LoyaltyEarningSection extends StatelessWidget {
  const LoyaltyEarningSection({super.key});

  @override
  Widget build(BuildContext context) {
    final LoyaltyController loyalty = context.read<LoyaltyController>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.card(),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(
              Icons.stars_rounded,
              size: 23,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('آلية كسب النقاط', style: AppText.cardTitle),
                const SizedBox(height: 3),
                Text(
                  'النقاط بتتحسب على إجمالي الفاتورة وبتتقرّب للأقل',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          SizedBox(
            width: 180,
            child: LoyaltyRateField(
              label: 'نقطة لكل جنيه',
              controller: loyalty.rateController,
              icon: Icons.stars_outlined,
              enabled: loyalty.canEdit,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: 180,
            child: LoyaltyRateField(
              label: 'قيمة النقطة (ج.م)',
              controller: loyalty.pointValueController,
              icon: Icons.payments_outlined,
              enabled: loyalty.canEdit,
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          const LoyaltyExampleCard(),
        ],
      ),
    );
  }
}
