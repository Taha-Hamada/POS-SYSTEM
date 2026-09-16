import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/payment_controller.dart';
import 'payment_stat.dart';

/// شاشة النجاح اللي بتظهر بعد تأكيد الدفع لحد ما الحوار يقفل.
class PaymentSuccessView extends StatelessWidget {
  const PaymentSuccessView({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final PaymentController payment = context.read<PaymentController>();

    final Animation<double> scale = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.65, curve: Curves.elasticOut),
    );
    final Animation<double> fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: 56,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ScaleTransition(
            scale: scale,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 62,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FadeTransition(
            opacity: fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'تم الدفع بنجاح',
                  style: AppText.pageTitle.copyWith(fontSize: 24),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'جارٍ تسجيل الفاتورة…',
                  style: AppText.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: AppRadius.lgAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PaymentStat(
                        label: 'المدفوع',
                        value: Fmt.money(payment.paid),
                        valueStyle: AppText.amountMd.copyWith(fontSize: 17),
                        labelSize: 11.5,
                        alignment: CrossAxisAlignment.center,
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        color: AppColors.border,
                      ),
                      PaymentStat(
                        label: 'الباقي',
                        value: Fmt.money(payment.change),
                        valueStyle: AppText.amountMd.copyWith(
                          fontSize: 17,
                          color: AppColors.success,
                        ),
                        labelSize: 11.5,
                        alignment: CrossAxisAlignment.center,
                      ),
                    ],
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
