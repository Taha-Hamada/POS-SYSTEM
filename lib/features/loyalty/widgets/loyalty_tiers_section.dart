import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/loyalty_tier.dart';
import '../../../theme/app_theme.dart';
import '../controllers/loyalty_controller.dart';
import 'loyalty_tier_card.dart';
import 'loyalty_tier_dialog.dart';

/// قسم مستويات العضوية.
class LoyaltyTiersSection extends StatelessWidget {
  const LoyaltyTiersSection({super.key});

  Future<void> _edit(BuildContext context, LoyaltyTier tier) async {
    final LoyaltyController loyalty = context.read<LoyaltyController>();

    final LoyaltyTier? edited = await showLoyaltyTierDialog(context, tier);
    if (edited != null) loyalty.updateTier(edited);
  }

  @override
  Widget build(BuildContext context) {
    final LoyaltyController loyalty = context.watch<LoyaltyController>();
    final List<LoyaltyTier> tiers = loyalty.tiers;
    final String? problem = loyalty.validationError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('مستويات العضوية', style: AppText.sectionTitle),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'العميل بيترقّى تلقائي بإجمالي مشترياته، وخصم مستواه بيتطبق على كل فاتورة',
                style: AppText.caption,
              ),
            ),
          ],
        ),
        if (problem != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            problem,
            style: AppText.caption.copyWith(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < tiers.length; i++) ...<Widget>[
                Expanded(
                  child: LoyaltyTierCard(
                    tier: tiers[i],
                    membersCount: loyalty.membersCountFor(tiers[i]),
                    onEdit: loyalty.canEdit
                        ? () => _edit(context, tiers[i])
                        : null,
                  ),
                ),
                if (i != tiers.length - 1) const SizedBox(width: AppSpacing.lg),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
