import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/employees_list_controller.dart';
import 'employees_branch_dropdown.dart';
import 'employees_role_dropdown.dart';

/// شريط فوق الجدول: العنوان والعدّاد والبحث وفلاتر الدور والفرع.
class EmployeesFilterBar extends StatelessWidget {
  const EmployeesFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final EmployeesListController employees = context
        .watch<EmployeesListController>();

    return Row(
      children: <Widget>[
        Text('قائمة الموظفين', style: AppText.sectionTitle),
        const SizedBox(width: AppSpacing.md),
        Text('(${Fmt.count(employees.visibleCount)})', style: AppText.caption),
        const Spacer(),
        SearchField(
          controller: employees.searchController,
          hint: 'ابحث بالاسم أو الدور…',
          onChanged: employees.setQuery,
        ),
        const SizedBox(width: AppSpacing.md),
        const EmployeesRoleDropdown(),
        const SizedBox(width: AppSpacing.md),
        const EmployeesBranchDropdown(),
      ],
    );
  }
}
