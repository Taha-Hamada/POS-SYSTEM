import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/data/branches_repository.dart';
import '../../../core/models/expense.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/expenses_controller.dart';
import '../data/expenses_repository.dart';
import '../widgets/expenses_filter_bar.dart';
import '../widgets/expenses_stat_cards.dart';
import '../widgets/expenses_table.dart';
import 'add_expense_dialog.dart';

/// شاشة المصروفات — بتجمّع البطاقات وشريط الفلترة والجدول بس.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  Future<void> _addExpense(BuildContext context) async {
    final ExpensesController expenses = context.read<ExpensesController>();

    final Expense? created = await showAddExpenseDialog(
      context,
      branches: expenses.branches,
      knownCategories: expenses.categoryNames,
    );

    if (created == null || !context.mounted) return;

    await expenses.addCreated(created);
    if (!context.mounted) return;

    showPlainSnackBar(
      context,
      'اتسجل المصروف ${created.number}: '
      '${created.category} بقيمة ${Fmt.money(created.amount)}',
      width: 480,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ApiClient api = context.read<ApiClient>();

    return ChangeNotifierProvider<ExpensesController>(
      create: (_) => ExpensesController(
        ExpensesRepository(api),
        BranchesRepository(api),
      )..load(),
      child: Builder(
        builder: (BuildContext context) {
          final bool canAdd =
              context.read<SessionController>().can('expense:manage');

          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'المصروفات',
                  subtitle: 'تسجيل ومتابعة مصروفات التشغيل عبر الفروع',
                  actions: <Widget>[
                    if (canAdd)
                      PrimaryButton(
                        label: 'إضافة مصروف',
                        icon: Icons.add_rounded,
                        onPressed: () => _addExpense(context),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const ExpensesStatCards(),
                const SizedBox(height: AppSpacing.xl),
                const ExpensesFilterBar(),
                const SizedBox(height: AppSpacing.lg),
                const Expanded(child: ExpensesTable()),
              ],
            ),
          );
        },
      ),
    );
  }
}
