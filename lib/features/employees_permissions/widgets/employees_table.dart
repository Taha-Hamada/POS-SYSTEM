import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/employee.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/hover_row_action.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/employees_list_controller.dart';
import 'employee_role_cell.dart';
import 'employees_table_footer.dart';

enum _EmployeeAction { edit, resetPassword, toggleActive }

/// جدول الموظفين.
class EmployeesTable extends StatelessWidget {
  const EmployeesTable({
    super.key,
    this.onEdit,
    this.onToggleActive,
    this.onResetPassword,
    this.onPermissions,
  });

  /// كلها null لو المستخدم مالوش إدارة الموظفين، فالإجراءات بتستخبى.
  final ValueChanged<Employee>? onEdit;
  final ValueChanged<Employee>? onToggleActive;
  final ValueChanged<Employee>? onResetPassword;

  /// صلاحيات الموظف نفسه — من غير الصلاحية بنودّي لشاشة صلاحيات الأدوار.
  final ValueChanged<Employee>? onPermissions;

  static const List<AppTableColumn> _columns = <AppTableColumn>[
    AppTableColumn('الموظف', size: ColumnSize.L, sortable: true),
    AppTableColumn('الدور', size: ColumnSize.M, sortable: true),
    AppTableColumn('الفرع', size: ColumnSize.M, sortable: true),
    AppTableColumn('الحالة', size: ColumnSize.S, sortable: true),
    AppTableColumn('آخر دخول', size: ColumnSize.M, sortable: true),
    // زرار الصلاحيات + قايمة الإجراءات محتاجين العرض ده، وأقل منه بيقطعهم.
    AppTableColumn('', fixedWidth: 210),
  ];

  bool get _hasActions =>
      onEdit != null || onToggleActive != null || onResetPassword != null;

  List<Widget> _cells(BuildContext context, Employee e, bool hovered) {
    final DateTime? lastLogin = e.lastLoginAt;

    return <Widget>[
      TableCells.avatarName(
        e.name,
        e.initials,
        color: e.isActive ? AppColors.accent : AppColors.textMuted,
        subtitle: e.phone.isEmpty ? '@${e.username}' : e.phone,
      ),
      EmployeeRoleCell(employee: e),
      Text(
        e.branchName ?? 'كل الفروع',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.body.copyWith(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      StatusBadge(
        label: e.isActive ? 'نشط' : 'موقوف',
        tone: e.isActive ? StatusTone.success : StatusTone.neutral,
      ),
      if (lastLogin == null)
        Text('لم يسجّل دخول', style: AppText.caption.copyWith(fontSize: 12.5))
      else
        TableCells.twoLine(Fmt.date(lastLogin), Fmt.time(lastLogin)),
      HoverRowAction(
        hovered: hovered,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SecondaryButton(
              label: 'الصلاحيات',
              size: AppButtonSize.small,
              tone: SecondaryButtonTone.accent,
              onPressed: onPermissions == null
                  ? () => context.go('/employees/roles')
                  : () => onPermissions!(e),
            ),
            if (_hasActions) _actionsMenu(e),
          ],
        ),
      ),
    ];
  }

  Widget _actionsMenu(Employee e) {
    return PopupMenuButton<_EmployeeAction>(
      tooltip: 'إجراءات الموظف',
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: AppColors.textMuted,
      ),
      onSelected: (_EmployeeAction action) => switch (action) {
        _EmployeeAction.edit => onEdit?.call(e),
        _EmployeeAction.resetPassword => onResetPassword?.call(e),
        _EmployeeAction.toggleActive => onToggleActive?.call(e),
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_EmployeeAction>>[
        if (onEdit != null)
          const PopupMenuItem<_EmployeeAction>(
            value: _EmployeeAction.edit,
            child: Text('تعديل البيانات'),
          ),
        if (onResetPassword != null)
          const PopupMenuItem<_EmployeeAction>(
            value: _EmployeeAction.resetPassword,
            child: Text('إعادة تعيين كلمة السر'),
          ),
        if (onToggleActive != null)
          PopupMenuItem<_EmployeeAction>(
            value: _EmployeeAction.toggleActive,
            child: Text(
              e.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب',
              style: TextStyle(
                color: e.isActive ? AppColors.danger : AppColors.success,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final EmployeesListController employees = context
        .watch<EmployeesListController>();

    if (employees.isFirstLoad) {
      return const LoadingView(message: 'بنحمّل الموظفين…');
    }

    if (employees.hasFailed && employees.totalCount == 0) {
      return ErrorView(
        message: employees.errorMessage!,
        onRetry: employees.retry,
      );
    }

    return AppDataTable(
      minWidth: 1080,
      rowHeight: 66,
      sortColumnIndex: employees.sortIndex,
      sortAscending: employees.sortAscending,
      onSort: employees.sortBy,
      emptyMessage: 'لا يوجد موظفون مطابقون للبحث',
      emptyIcon: Icons.badge_outlined,
      columns: _columns,
      rows: <AppTableRow>[
        for (final Employee e in employees.rows)
          AppTableRow(
            onTap: onEdit == null ? null : () => onEdit!(e),
            cellsBuilder: (bool hovered) => _cells(context, e, hovered),
          ),
      ],
      footer: const EmployeesTableFooter(),
    );
  }
}
