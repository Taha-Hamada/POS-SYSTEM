import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// طرق الدفع المتاحة في الفاتورة.
enum PaymentMethod { cash, card, wallet, credit }

extension PaymentMethodInfo on PaymentMethod {
  /// الاسم اللي الباك اند بيفهمه.
  String get apiValue => switch (this) {
        PaymentMethod.cash => 'cash',
        PaymentMethod.card => 'card',
        PaymentMethod.wallet => 'wallet',
        PaymentMethod.credit => 'credit',
      };

  String get label => switch (this) {
        PaymentMethod.cash => 'كاش',
        PaymentMethod.card => 'بطاقة',
        PaymentMethod.wallet => 'محفظة',
        PaymentMethod.credit => 'آجل',
      };

  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_rounded,
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.wallet => Icons.account_balance_wallet_rounded,
        PaymentMethod.credit => Icons.schedule_rounded,
      };

  Color get color => switch (this) {
        PaymentMethod.cash => AppColors.success,
        PaymentMethod.card => AppColors.info,
        PaymentMethod.wallet => AppColors.accent,
        PaymentMethod.credit => AppColors.warning,
      };

  String get hint => switch (this) {
        PaymentMethod.cash => 'المبلغ المستلم من العميل',
        PaymentMethod.card => 'المبلغ المسحوب على البطاقة',
        PaymentMethod.wallet => 'المبلغ المحوّل من المحفظة',
        PaymentMethod.credit => 'يُسجّل على حساب العميل',
      };
}
