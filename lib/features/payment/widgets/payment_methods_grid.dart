import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/payment_controller.dart';
import '../../../core/models/payment_method.dart';
import 'payment_method_card.dart';

/// شبكة 2×2 لطرق الدفع.
///
/// بدون GridView عشان تفضل قابلة للقياس جوه عمود بارتفاع طبيعي.
class PaymentMethodsGrid extends StatelessWidget {
  const PaymentMethodsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final PaymentController payment = context.watch<PaymentController>();

    Widget card(int index) {
      final PaymentMethod method = PaymentMethod.values[index];
      return PaymentMethodCard(
        method: method,
        selected: payment.method == method,
        used: payment.isUsed(method),
        onTap: () => payment.selectMethod(method),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int row = 0; row < 2; row++) ...<Widget>[
          if (row > 0) const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 92,
            child: Row(
              children: <Widget>[
                for (int col = 0; col < 2; col++) ...<Widget>[
                  if (col > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(child: card(row * 2 + col)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
