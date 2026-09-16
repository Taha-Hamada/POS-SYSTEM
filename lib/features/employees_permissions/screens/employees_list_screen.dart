import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/data/branches_repository.dart';
import '../../../core/models/employee.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/employees_list_controller.dart';
import '../data/employees_repository.dart';
import '../widgets/employee_form_dialog.dart';
import '../widgets/employee_permissions_dialog.dart';
import '../widgets/employees_filter_bar.dart';
import '../widgets/employees_stat_cards.dart';
import '../widgets/employees_table.dart';

/// شاشة الموظفين — بتجمّع الهيدر والبطاقات وشريط الفلترة والجدول بس.
class EmployeesListScreen extends StatelessWidget {
  const EmployeesListScreen({super.key});

  Future<void> _openForm(BuildContext context, {Employee? existing}) async {
    final EmployeesListController employees = context
        .read<EmployeesListController>();

    final bool? saved = await showEmployeeFormDialog(
      context,
      branches: employees.branches,
      initial: existing,
      onSubmit: (EmployeeInput input) =>
          employees.save(input, existing: existing),
    );

    if (saved != true || !context.mounted) return;

    showAppSnackBar(
      context,
      existing == null ? 'اتضاف الموظف الجديد' : 'اتحفظت بيانات الموظف',
      width: 460,
    );
  }

  Future<void> _toggleActive(BuildContext context, Employee employee) async {
    final String? error = await context
        .read<EmployeesListController>()
        .setActive(employee, isActive: !employee.isActive);
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      error ??
          (employee.isActive
              ? 'اتوقف حساب «${employee.name}» واتقفلت جلساته'
              : 'اتفعّل حساب «${employee.name}»'),
      isError: error != null,
      width: 480,
    );
  }

  /// صلاحيات الموظف نفسه — زيادة أو استثناءات فوق باقة دوره.
  Future<void> _permissions(BuildContext context, Employee employee) async {
    final EmployeesListController employees = context
        .read<EmployeesListController>();

    final PermissionOverrides? overrides = await showEmployeePermissionsDialog(
      context,
      employee: employee,
      rolePermissions: employees.rolePermissionsOf(employee),
      allPermissions: employees.catalog.permissions,
    );
    if (overrides == null || !context.mounted) return;

    final String? error = await employees.savePermissions(
      employee,
      granted: overrides.granted,
      revoked: overrides.revoked,
    );
    if (!context.mounted) return;

    final int count = overrides.granted.length + overrides.revoked.length;

    showAppSnackBar(
      context,
      error ??
          (count == 0
              ? 'رجعت صلاحيات «${employee.name}» لصلاحيات دوره'
              : 'اتحفظت صلاحيات «${employee.name}» — $count استثناء'),
      isError: error != null,
      width: 480,
    );
  }

  Future<void> _resetPassword(BuildContext context, Employee employee) async {
    final EmployeesListController employees = context
        .read<EmployeesListController>();

    final String? password = await showResetPasswordDialog(
      context,
      employee: employee,
    );
    if (password == null || !context.mounted) return;

    final String? error = await employees.resetPassword(employee, password);
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      error ?? 'اتغيرت كلمة سر «${employee.name}»',
      isError: error != null,
      width: 460,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ApiClient api = context.read<ApiClient>();
    final bool canManage = context.read<SessionController>().can('user:manage');

    return ChangeNotifierProvider<EmployeesListController>(
      create: (_) => EmployeesListController(
        EmployeesRepository(api),
        BranchesRepository(api),
      )..load(),
      child: Builder(
        builder: (BuildContext context) {
          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'الموظفين',
                  subtitle: 'فريق العمل عبر كل الفروع وحالات الدخول',
                  actions: <Widget>[
                    SecondaryButton(
                      label: 'الأدوار والصلاحيات',
                      icon: Icons.shield_outlined,
                      tone: SecondaryButtonTone.accent,
                      onPressed: () => context.go('/employees/roles'),
                    ),
                    if (canManage)
                      PrimaryButton(
                        label: 'إضافة موظف',
                        icon: Icons.person_add_alt_1_rounded,
                        onPressed: () => _openForm(context),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const EmployeesStatCards(),
                const SizedBox(height: AppSpacing.xl),
                const EmployeesFilterBar(),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: EmployeesTable(
                    onEdit: canManage
                        ? (Employee e) => _openForm(context, existing: e)
                        : null,
                    onToggleActive: canManage
                        ? (Employee e) => _toggleActive(context, e)
                        : null,
                    onResetPassword: canManage
                        ? (Employee e) => _resetPassword(context, e)
                        : null,
                    onPermissions: canManage
                        ? (Employee e) => _permissions(context, e)
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
