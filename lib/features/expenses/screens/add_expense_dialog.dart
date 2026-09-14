import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/branch.dart';
import '../../../core/models/expense.dart';
import '../../../core/session/session_controller.dart';
import '../../../theme/app_theme.dart';
import '../controllers/add_expense_controller.dart';
import '../data/expenses_repository.dart';
import '../widgets/add_expense_actions.dart';
import '../widgets/add_expense_fields.dart';
import '../widgets/add_expense_header.dart';

/// يفتح حوار إضافة مصروف ويرجّع المصروف اللي السيرفر قبله (أو null لو اتلغى).
///
/// الفروع والبنود المعروفة بتيجي جاهزة من شاشة المصروفات بدل ما الحوار
/// يعيد تحميلها مع كل فتح.
Future<Expense?> showAddExpenseDialog(
  BuildContext context, {
  required List<Branch> branches,
  required List<String> knownCategories,
}) {
  final ExpensesRepository repository =
      ExpensesRepository(context.read<ApiClient>());
  final String? userBranch = context.read<SessionController>().user?.branchId;

  return showDialog<Expense>(
    context: context,
    builder: (BuildContext context) =>
        ChangeNotifierProvider<AddExpenseController>(
      create: (_) => AddExpenseController(
        repository,
        branches: branches,
        knownCategories: knownCategories,
        branchId: userBranch,
      ),
      child: const AddExpenseDialog(),
    ),
  );
}

/// حوار إضافة مصروف — بيجمّع الهيدر والحقول والأزرار بس.
class AddExpenseDialog extends StatelessWidget {
  const AddExpenseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AddExpenseHeader(),
              SizedBox(height: AppSpacing.xl),
              AddExpenseFields(),
              SizedBox(height: AppSpacing.xxl),
              AddExpenseActions(),
            ],
          ),
        ),
      ),
    );
  }
}
