import 'package:flutter/material.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/models/customer.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import 'loyalty_points_row.dart';

/// بطاقة رصيد نقاط الولاء الداكنة.
class LoyaltyBalanceCard extends StatelessWidget {
  const LoyaltyBalanceCard({
    super.key,
    required this.customer,
    required this.earned,
    required this.redeemed,
  });

  final Customer customer;
  final int earned;
  final int redeemed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.18),
                  borderRadius: AppRadius.mdAll,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  size: 21,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'رصيد النقاط الحالي',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOnDarkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              Fmt.count(customer.points),
              style: AppText.amountHero.copyWith(
                fontSize: 56,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'تعادل ${Fmt.money(customer.points / 10)} خصم',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textOnDarkMuted,
            ),
          ),
          const Spacer(),
          LoyaltyPointsRow(
            label: 'نقاط مكتسبة',
            value: earned,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          LoyaltyPointsRow(
            label: 'نقاط مستبدلة',
            value: redeemed,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'استبدال نقاط',
            icon: Icons.redeem_rounded,
            expanded: true,
            onPressed: customer.points > 0 ? () {} : null,
          ),
        ],
      ),
    );
  }
}
