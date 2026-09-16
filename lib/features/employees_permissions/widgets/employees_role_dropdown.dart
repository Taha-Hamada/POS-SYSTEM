import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_role.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../utils/formatters.dart';
import '../controllers/employees_list_controller.dart';

/// فلتر الدور الوظيفي.
class EmployeesRoleDropdown extends StatelessWidget {
  const EmployeesRoleDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final EmployeesListController employees = context
        .watch<EmployeesListController>();

    return AppDropdown<String?>(
      value: employees.role,
      width: 180,
      icon: Icons.shield_outlined,
      onChanged: employees.setRole,
      items: <AppDropdownItem<String?>>[
        const AppDropdownItem<String?>(
          value: null,
          label: 'كل الأدوار',
          icon: Icons.apps_rounded,
        ),
        for (final UserRole r in UserRole.values)
          AppDropdownItem<String?>(
            value: r.apiValue,
            label: r.label,
            icon: r.icon,
            trailing: Fmt.count(employees.countForRole(r)),
          ),
      ],
    );
  }
}
