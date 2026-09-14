import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/payment_controller.dart';
import '../../../core/models/payment_method.dart';

/// مبالغ سريعة (+50، +100، +200) وزرار «بالظبط» للمتبقي.
class PaymentQuickAmounts extends StatelessWidget {
  const PaymentQuickAmounts({super.key});

  @override
  Widget build(BuildContext context) {
    final PaymentController payment = context.watch<PaymentController>();
    // الآجل بياخد المتبقي كله — مفيش معنى لزيادة المبلغ يدويًا
    final bool isCredit = payment.method == PaymentMethod.credit;

    return Row(
      children: <Widget>[
        for (final double v in <double>[50, 100, 200]) ...<Widget>[
          Expanded(
            child: SecondaryButton(
              label: '+${Fmt.count(v)}',
              size: AppButtonSize.small,
              expanded: true,
              onPressed: isCredit ? null : () => payment.addQuick(v),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: SecondaryButton(
            label: 'بالظبط',
            size: AppButtonSize.small,
            expanded: true,
            tone: SecondaryButtonTone.accent,
            onPressed: payment.setExact,
          ),
        ),
      ],
    );
  }
}
