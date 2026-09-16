import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/employee.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../theme/app_theme.dart';
import '../../employees_permissions/widgets/employee_form_dialog.dart';
import '../controllers/settings_controller.dart';
import 'settings_panel.dart';
import 'user_account_row.dart';

/// قسم حسابات المستخدمين.
class UsersSettingsSection extends StatelessWidget {
  const UsersSettingsSection({super.key});

  Future<void> _resetPassword(BuildContext context, Employee employee) async {
    final SettingsController settings = context.read<SettingsController>();

    final String? password = await showResetPasswordDialog(
      context,
      employee: employee,
    );
    if (password == null || !context.mounted) return;

    final String? error = await settings.resetPassword(employee, password);
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
    final SettingsController settings = context.watch<SettingsController>();
    final bool canManage = context.read<SessionController>().can('user:manage');
    final List<Employee> users = settings.users;

    return SettingsPanel(
      children: <Widget>[
        if (!settings.canViewUsers)
          Text(
            'عرض حسابات المستخدمين محتاج صلاحية الموظفين',
            style: AppText.caption,
          )
        else if (users.isEmpty)
          Text('لا يوجد مستخدمين', style: AppText.caption)
        else
          for (int i = 0; i < users.length; i++)
            UserAccountRow(
              employee: users[i],
              isLast: i == users.length - 1,
              onResetPassword: canManage
                  ? () => _resetPassword(context, users[i])
                  : null,
            ),
      ],
    );
  }
}
