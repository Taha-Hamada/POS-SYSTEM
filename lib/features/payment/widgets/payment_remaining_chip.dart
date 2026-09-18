import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/payment_controller.dart';

/// شارة تحت الإجمالي بتقول لسه فاضل كام — أو الباقي للعميل.
class PaymentRemainingChip extends StatelessWidget {
  const PaymentRemainingChip({super.key});

  @override
  Widget build(BuildContext context) {
    final PaymentController payment = context.watch<PaymentController>();
    final bool covered = payment.isCovered;
    final double change = payment.change;
    final double overpay = payment.nonCashOverpay;

    // الزيادة في غير الكاش غلط إدخال مش باقي — مفيش فكّة من الفيزا.
    final Color color = overpay > 0
        ? AppColors.danger
        : covered
        ? AppColors.success
        : AppColors.warning;

    final String label = overpay > 0
        ? 'زيادة مش كاش: ${Fmt.money(overpay)} — قلّلها'
        : covered
        ? change > 0.005
              ? 'الباقي للعميل: ${Fmt.money(change)}'
              : 'المبلغ مكتمل'
        : 'المتبقي: ${Fmt.money(payment.remainingAfter)}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            overpay > 0
                ? Icons.error_outline_rounded
                : covered
                ? Icons.check_circle_rounded
                : Icons.hourglass_bottom_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
