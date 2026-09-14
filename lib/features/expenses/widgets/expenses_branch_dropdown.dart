import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/branch.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../controllers/expenses_controller.dart';

/// فلتر الفرع في شاشة المصروفات.
class ExpensesBranchDropdown extends StatelessWidget {
  const ExpensesBranchDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final ExpensesController expenses = context.watch<ExpensesController>();

    return AppDropdown<String?>(
      value: expenses.branchId,
      width: 200,
      icon: Icons.store_outlined,
      onChanged: expenses.setBranch,
      items: <AppDropdownItem<String?>>[
        const AppDropdownItem<String?>(
          value: null,
          label: 'كل الفروع',
          icon: Icons.apps_rounded,
        ),
        for (final Branch b in expenses.branches)
          AppDropdownItem<String?>(value: b.id, label: b.name),
      ],
    );
  }
}
