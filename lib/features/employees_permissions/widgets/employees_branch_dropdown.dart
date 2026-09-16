import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/branch.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../controllers/employees_list_controller.dart';

/// فلتر الفرع في شاشة الموظفين.
class EmployeesBranchDropdown extends StatelessWidget {
  const EmployeesBranchDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final EmployeesListController employees = context
        .watch<EmployeesListController>();

    return AppDropdown<String?>(
      value: employees.branchId,
      width: 220,
      icon: Icons.store_outlined,
      onChanged: employees.setBranch,
      items: <AppDropdownItem<String?>>[
        const AppDropdownItem<String?>(
          value: null,
          label: 'كل الفروع',
          icon: Icons.apps_rounded,
        ),
        for (final Branch b in employees.branches)
          AppDropdownItem<String?>(value: b.id, label: b.name),
      ],
    );
  }
}
