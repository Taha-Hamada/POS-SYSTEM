import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_dropdown.dart';
import '../controllers/expenses_controller.dart';

/// فلتر بند المصروف.
///
/// البنود نص حر على السيرفر، فالقائمة هي البنود اللي اتسجّلت فعلًا مش قايمة
/// ثابتة في الكود.
class ExpensesCategoryDropdown extends StatelessWidget {
  const ExpensesCategoryDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final ExpensesController expenses = context.watch<ExpensesController>();

    return AppDropdown<String?>(
      value: expenses.category,
      width: 190,
      icon: Icons.category_outlined,
      onChanged: expenses.setCategory,
      items: <AppDropdownItem<String?>>[
        const AppDropdownItem<String?>(
          value: null,
          label: 'كل البنود',
          icon: Icons.apps_rounded,
        ),
        for (final String c in expenses.categoryNames)
          AppDropdownItem<String?>(value: c, label: c),
      ],
    );
  }
}
