import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/expenses_controller.dart';
import 'expenses_branch_dropdown.dart';
import 'expenses_category_dropdown.dart';
import 'expenses_status_dropdown.dart';

/// شريط فوق الجدول: العنوان والعدّاد والبحث والفلاتر التلاتة.
class ExpensesFilterBar extends StatelessWidget {
  const ExpensesFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ExpensesController expenses = context.watch<ExpensesController>();

    return Row(
      children: <Widget>[
        Text('سجل المصروفات', style: AppText.sectionTitle),
        const SizedBox(width: AppSpacing.md),
        Text('(${Fmt.count(expenses.visibleCount)})', style: AppText.caption),
        const Spacer(),
        SearchField(
          controller: expenses.searchController,
          hint: 'ابحث بالرقم أو الملاحظة أو البند…',
          width: 240,
          onChanged: expenses.setQuery,
        ),
        const SizedBox(width: AppSpacing.md),
        const ExpensesCategoryDropdown(),
        const SizedBox(width: AppSpacing.md),
        const ExpensesBranchDropdown(),
        const SizedBox(width: AppSpacing.md),
        const ExpensesStatusDropdown(),
      ],
    );
  }
}
