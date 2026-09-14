import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// خلية طريقة الدفع في سجل الفواتير.
class InvoicePaymentMethodCell extends StatelessWidget {
  const InvoicePaymentMethodCell({super.key, required this.method});

  /// كود طريقة الدفع زي ما السيرفر بيرجّعه: cash أو card أو wallet أو credit.
  final String method;

  IconData get _icon => switch (method) {
        'cash' => Icons.payments_outlined,
        'card' => Icons.credit_card_rounded,
        'wallet' => Icons.account_balance_wallet_outlined,
        _ => Icons.schedule_rounded,
      };

  String get _label => switch (method) {
        'cash' => 'كاش',
        'card' => 'بطاقة',
        'wallet' => 'محفظة',
        'credit' => 'آجل',
        _ => method,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(_icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(_label, style: AppText.body.copyWith(fontSize: 13)),
      ],
    );
  }
}
