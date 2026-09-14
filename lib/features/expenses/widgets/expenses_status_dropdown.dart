import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/expense.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../controllers/expenses_controller.dart';

/// فلتر حالة المصروف.
class ExpensesStatusDropdown extends StatelessWidget {
  const ExpensesStatusDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final ExpensesController expenses = context.watch<ExpensesController>();

    return AppDropdown<ExpenseStatus?>(
      value: expenses.status,
      width: 170,
      icon: Icons.flag_outlined,
      onChanged: expenses.setStatus,
      items: <AppDropdownItem<ExpenseStatus?>>[
        const AppDropdownItem<ExpenseStatus?>(
          value: null,
          label: 'كل الحالات',
          icon: Icons.apps_rounded,
        ),
        for (final ExpenseStatus s in ExpenseStatus.values)
          AppDropdownItem<ExpenseStatus?>(value: s, label: s.label),
      ],
    );
  }
}
