import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/payment_controller.dart';
import 'payment_remaining_chip.dart';

/// هيدر شاشة الدفع: بيانات الفاتورة والإجمالي المطلوب بخط ضخم.
class PaymentHeader extends StatelessWidget {
  const PaymentHeader({
    super.key,
    required this.itemsCount,
    required this.customerName,
  });

  final double itemsCount;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final double total = context.read<PaymentController>().total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppRadius.xl),
          topLeft: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.receipt_long_rounded,
                size: 17,
                color: AppColors.textOnDarkMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  '$customerName • ${Fmt.qty(itemsCount)} صنف',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textOnDarkMuted,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'إلغاء',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppColors.textOnDarkMuted,
                ),
              ),
            ],
          ),
          const Text(
            'الإجمالي المطلوب',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnDarkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(
                  Fmt.amount(total),
                  style: AppText.amountHero.copyWith(
                    fontSize: 46,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  Fmt.currencySymbol,
                  style: AppText.amountLg.copyWith(
                    color: AppColors.textOnDarkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const PaymentRemainingChip(),
        ],
      ),
    );
  }
}
