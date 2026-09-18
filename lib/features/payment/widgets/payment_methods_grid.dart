import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/payment_controller.dart';
import '../../../core/models/payment_method.dart';
import 'payment_method_card.dart';

/// شبكة طرق الدفع — صفّين على الأكتر، اتنين في كل صف.
///
/// بتتبني من [PaymentMethod.values] مش بعدد ثابت، عشان تفضل شغّالة لو
/// عدد الطرق اتغيّر (زي ما حصل لما الفيزا والمحفظة اتشالوا).
class PaymentMethodsGrid extends StatelessWidget {
  const PaymentMethodsGrid({super.key});

  static const int _perRow = 2;

  @override
  Widget build(BuildContext context) {
    final PaymentController payment = context.watch<PaymentController>();
    const List<PaymentMethod> methods = PaymentMethod.values;

    Widget card(PaymentMethod method) => PaymentMethodCard(
      method: method,
      selected: payment.method == method,
      used: payment.isUsed(method),
      onTap: () => payment.selectMethod(method),
    );

    final int rows = (methods.length + _perRow - 1) ~/ _perRow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int row = 0; row < rows; row++) ...<Widget>[
          if (row > 0) const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 92,
            child: Row(
              children: <Widget>[
                for (int col = 0; col < _perRow; col++) ...<Widget>[
                  if (col > 0) const SizedBox(width: AppSpacing.md),
                  // الخانة الفاضية في آخر صف بتفضل مساحة عشان العرض ميتغيرش.
                  Expanded(
                    child: row * _perRow + col < methods.length
                        ? card(methods[row * _perRow + col])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
