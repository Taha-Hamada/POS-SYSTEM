import 'package:flutter/material.dart';

import 'payment_body.dart';
import 'payment_footer.dart';
import 'payment_header.dart';

/// محتوى شاشة الدفع قبل التأكيد: هيدر + جسم + فوتر.
class PaymentContent extends StatelessWidget {
  const PaymentContent({
    super.key,
    required this.itemsCount,
    required this.customerName,
    required this.onConfirm,
  });

  final double itemsCount;
  final String customerName;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PaymentHeader(itemsCount: itemsCount, customerName: customerName),
        const Flexible(child: PaymentBody()),
        PaymentFooter(onConfirm: onConfirm),
      ],
    );
  }
}
