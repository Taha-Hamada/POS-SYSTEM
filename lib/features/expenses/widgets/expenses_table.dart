import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/expense.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/hover_row_action.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/expenses_controller.dart';
import 'expense_category_badge.dart';
import 'expenses_table_footer.dart';
import 'reject_expense_dialog.dart';

/// جدول المصروفات مع اعتماد ورفض الصفوف المعلّقة.
class ExpensesTable extends StatelessWidget {
  const ExpensesTable({super.key});

  /// عمود الفرع بيتفرز محليًا لأن السيرفر بيفرز بمعرّف الفرع مش باسمه.
  static const List<AppTableColumn> _columns = <AppTableColumn>[
    AppTableColumn('التاريخ', size: ColumnSize.M, sortable: true),
    AppTableColumn('البند', size: ColumnSize.M, sortable: true),
    AppTableColumn('الفرع', size: ColumnSize.M, sortable: true),
    AppTableColumn('الملاحظة', size: ColumnSize.L),
    AppTableColumn('المبلغ', size: ColumnSize.S, sortable: true, numeric: true),
    AppTableColumn('الحالة', size: ColumnSize.M, sortable: true),
  ];

  Future<void> _approve(BuildContext context, Expense expense) async {
    final ExpensesController expenses = context.read<ExpensesController>();

    final String? error = await expenses.review(expense, approve: true);
    if (!context.mounted) return;

    showPlainSnackBar(
      context,
      error ?? 'تم اعتماد ${expense.number} بقيمة ${Fmt.money(expense.amount)}',
      width: 480,
    );
  }

  Future<void> _reject(BuildContext context, Expense expense) async {
    final ExpensesController expenses = context.read<ExpensesController>();

    // السيرفر بيرفض الرفض من غير سبب، فبنسأل عليه الأول.
    final String? reason = await showRejectExpenseDialog(context, expense);
    if (reason == null || !context.mounted) return;

    final String? error =
        await expenses.review(expense, approve: false, reason: reason);
    if (!context.mounted) return;

    showPlainSnackBar(context, error ?? 'تم رفض ${expense.number}', width: 480);
  }

  List<Widget> _cells(BuildContext context, Expense e, bool hovered) {
    final bool canReview =
        context.read<SessionController>().can('expense:approve');

    return <Widget>[
      TableCells.twoLine(Fmt.date(e.date), e.number),
      ExpenseCategoryBadge(category: e.category),
      Text(
        e.branchName.isEmpty ? '—' : e.branchName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.body.copyWith(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      Text(
        e.note.isEmpty ? '—' : e.note,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.body.copyWith(fontSize: 13),
      ),
      TableCells.amount(e.amount, color: AppColors.danger),
      if (e.isPending && canReview)
        HoverRowAction(
          hovered: hovered,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ReviewButton(
                icon: Icons.check_rounded,
                tooltip: 'اعتماد',
                color: AppColors.success,
                onPressed: () => _approve(context, e),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ReviewButton(
                icon: Icons.close_rounded,
                tooltip: 'رفض',
                color: AppColors.danger,
                onPressed: () => _reject(context, e),
              ),
            ],
          ),
        )
      else
        StatusBadge(label: e.status.label, tone: e.status.tone),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ExpensesController expenses = context.watch<ExpensesController>();

    if (expenses.isFirstLoad) {
      return const LoadingView(message: 'بنجيب المصروفات…');
    }

    if (expenses.hasFailed) {
      return ErrorView(
        message: expenses.errorMessage!,
        onRetry: expenses.retry,
      );
    }

    return AppDataTable(
      minWidth: 1000,
      rowHeight: 62,
      sortColumnIndex: expenses.sortIndex,
      sortAscending: expenses.sortAscending,
      onSort: expenses.sortBy,
      emptyMessage: 'لا توجد مصروفات مطابقة للفلتر',
      emptyIcon: Icons.receipt_long_outlined,
      columns: _columns,
      rows: <AppTableRow>[
        for (final Expense e in expenses.rows)
          AppTableRow(
            cellsBuilder: (bool hovered) => _cells(context, e, hovered),
          ),
      ],
      footer: const ExpensesTableFooter(),
    );
  }
}

/// زرار اعتماد/رفض صغير بيظهر مكان شارة الحالة عند الـHover.
class _ReviewButton extends StatelessWidget {
  const _ReviewButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.smAll,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: AppRadius.smAll,
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
