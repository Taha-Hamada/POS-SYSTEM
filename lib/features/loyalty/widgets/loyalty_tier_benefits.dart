import 'package:flutter/material.dart';

import '../../../core/models/loyalty_tier.dart';
import '../../../theme/app_theme.dart';

/// قايمة مزايا المستوى في نص البطاقة.
class LoyaltyTierBenefits extends StatelessWidget {
  const LoyaltyTierBenefits({super.key, required this.tier});

  final LoyaltyTier tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('المزايا', style: AppText.label.copyWith(fontSize: 12)),
          const SizedBox(height: AppSpacing.md),
          if (tier.benefits.isEmpty)
            Text('لا توجد مزايا مكتوبة', style: AppText.caption)
          else
            for (final String benefit in tier.benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: Text(
                        benefit,
                        style: AppText.body.copyWith(
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
