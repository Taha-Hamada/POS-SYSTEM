import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/payment_controller.dart';
import '../../../core/models/payment_method.dart';

/// سطر فوق خانة المبلغ بيوضّح الطريقة المختارة ومعناها.
class PaymentMethodHintRow extends StatelessWidget {
  const PaymentMethodHintRow({super.key});

  @override
  Widget build(BuildContext context) {
    final PaymentMethod method =
        context.select((PaymentController p) => p.method);

    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            method.hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label.copyWith(fontSize: 12.5),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(method.icon, size: 15, color: method.color),
        const SizedBox(width: 5),
        Text(
          method.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: method.color,
          ),
        ),
      ],
    );
  }
}
