import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/employees_list_controller.dart';

/// فوتر الجدول: مبيعات اليوم للموظفين المعروضين وعددهم.
class EmployeesTableFooter extends StatelessWidget {
  const EmployeesTableFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final EmployeesListController employees = context
        .watch<EmployeesListController>();

    return Row(
      children: <Widget>[
        Text(
          'مبيعات اليوم للموظفين المعروضين: '
          '${Fmt.money(employees.visibleTodaySales)}',
          style: AppText.caption,
        ),
        const Spacer(),
        Text(
          '${Fmt.count(employees.visibleCount)} موظف',
          style: AppText.caption,
        ),
      ],
    );
  }
}
