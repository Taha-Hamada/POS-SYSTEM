import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/labeled_field.dart';

import '../controllers/returns_controller.dart';

/// اختيار طريقة الاسترداد.
class ReturnsRefundMethodField extends StatelessWidget {
  const ReturnsRefundMethodField({super.key});

  @override
  Widget build(BuildContext context) {
    final ReturnsController returns = context.watch<ReturnsController>();

    return LabeledField(
      label: 'طريقة الاسترداد',
      child: AppDropdown<String>(
        value: returns.refundMethod,
        width: double.infinity,
        height: 48,
        icon: Icons.account_balance_wallet_outlined,
        onChanged: returns.setRefundMethod,
        items: <AppDropdownItem<String>>[
          // المفتاح هو الاسم اللي السيرفر بيفهمه، والقيمة هي المعروضة.
          for (final MapEntry<String, String> m in kRefundMethods.entries)
            AppDropdownItem<String>(value: m.key, label: m.value),
        ],
      ),
    );
  }
}
