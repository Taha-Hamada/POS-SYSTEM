import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/product_profile_controller.dart';

/// الربح والهامش وقيمة المخزون بالسعر المكتوب دلوقتي — بتتحدّث مع كل حرف
/// عشان المستخدم يشوف أثر التعديل قبل ما يحفظ.
class ProductProfitRow extends StatelessWidget {
  const ProductProfitRow({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductProfileController p = context
        .watch<ProductProfileController>();

    final bool isLoss = p.profit < 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isLoss ? AppColors.dangerSoft : AppColors.surfaceAlt,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: isLoss ? AppColors.danger.withValues(alpha: 0.25) : AppColors.border,
        ),
      ),
      child: Row(
        children: <Widget>[
          _stat(
            'الربح للوحدة',
            Fmt.money(p.profit),
            color: isLoss ? AppColors.danger : AppColors.success,
          ),
          _divider(),
          _stat(
            'هامش الربح',
            Fmt.percent(p.margin),
            color: isLoss ? AppColors.danger : AppColors.textPrimary,
          ),
          _divider(),
          _stat('الرصيد الكلي', Fmt.count(p.totalOnHand)),
          _divider(),
          _stat('قيمة المخزون بالبيع', Fmt.moneyRounded(p.stockValue)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 34,
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    color: AppColors.border,
  );

  Widget _stat(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: AppText.label.copyWith(fontSize: 11.5)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: AppText.amountSm.copyWith(
                fontSize: 16,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
