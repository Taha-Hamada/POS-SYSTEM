import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// طرق الدفع المتاحة في الفاتورة والمرتجع والمصروف وأمر الشراء.
///
/// كاش وآجل بس — الفيزا والمحفظة اتشالوا من النظام.
enum PaymentMethod { cash, credit }

/// بيحوّل قيمة السيرفر لطريقة دفع، وبيرجّع الكاش لو الرد جه بقيمة مش معروفة.
PaymentMethod paymentMethodFromApi(String? value) => PaymentMethod.values
    .where((PaymentMethod m) => m.apiValue == value)
    .firstOrNull ??
    PaymentMethod.cash;

extension PaymentMethodInfo on PaymentMethod {
  /// الاسم اللي الباك اند بيفهمه.
  String get apiValue => switch (this) {
        PaymentMethod.cash => 'cash',
        PaymentMethod.credit => 'credit',
      };

  String get label => switch (this) {
        PaymentMethod.cash => 'كاش',
        PaymentMethod.credit => 'آجل',
      };

  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_rounded,
        PaymentMethod.credit => Icons.schedule_rounded,
      };

  Color get color => switch (this) {
        PaymentMethod.cash => AppColors.success,
        PaymentMethod.credit => AppColors.warning,
      };

  String get hint => switch (this) {
        PaymentMethod.cash => 'المبلغ المستلم من العميل',
        PaymentMethod.credit => 'يُسجّل على حساب العميل',
      };
}
