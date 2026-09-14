import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/expense.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/add_expense_controller.dart';

/// أزرار الإلغاء والحفظ في حوار المصروف.
class AddExpenseActions extends StatelessWidget {
  const AddExpenseActions({super.key});

  Future<void> _save(BuildContext context) async {
    final AddExpenseController form = context.read<AddExpenseController>();

    final Expense? created = await form.submit();
    if (!context.mounted) return;

    if (created == null) {
      showPlainSnackBar(context, form.saveError ?? 'مقدرناش نسجّل المصروف');
      return;
    }

    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final AddExpenseController form = context.watch<AddExpenseController>();

    return Row(
      children: <Widget>[
        Expanded(
          child: SecondaryButton(
            label: 'إلغاء',
            expanded: true,
            onPressed:
                form.isLoading ? null : () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: PrimaryButton(
            label: form.isLoading ? 'بنسجّل…' : 'حفظ المصروف',
            icon: Icons.check_rounded,
            expanded: true,
            onPressed: form.isValid ? () => _save(context) : null,
          ),
        ),
      ],
    );
  }
}
