import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../controllers/roles_permissions_controller.dart';
import '../data/employees_repository.dart';
import '../widgets/permissions_area.dart';
import '../widgets/roles_list_panel.dart';
import '../widgets/roles_permissions_footer.dart';

/// شاشة الأدوار والصلاحيات — بتجمّع قائمة الأدوار ومنطقة الصلاحيات والفوتر.
class RolesPermissionsScreen extends StatefulWidget {
  const RolesPermissionsScreen({super.key});

  @override
  State<RolesPermissionsScreen> createState() => _RolesPermissionsScreenState();
}

class _RolesPermissionsScreenState extends State<RolesPermissionsScreen>
    with SingleTickerProviderStateMixin {
  /// الكنترولر محتاج vsync عشان أنيميشن الـFade عند تبديل الدور.
  late final RolesPermissionsController _roles = RolesPermissionsController(
    EmployeesRepository(context.read<ApiClient>()),
    vsync: this,
    canEdit: context.read<SessionController>().can('user:manage'),
  )..load();

  @override
  void dispose() {
    _roles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RolesPermissionsController>.value(
      value: _roles,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xxl,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ScreenHeader(
                    title: 'الأدوار والصلاحيات',
                    subtitle:
                        'اختر دورًا من القائمة وتحكّم في صلاحياته داخل النظام',
                    leading: BackCircleButton(
                      onTap: () => context.go('/employees'),
                      tooltip: 'رجوع للموظفين',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Expanded(child: _RolesBody()),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          const RolesPermissionsFooter(),
        ],
      ),
    );
  }
}

class _RolesBody extends StatelessWidget {
  const _RolesBody();

  @override
  Widget build(BuildContext context) {
    final RolesPermissionsController roles = context
        .watch<RolesPermissionsController>();

    if (roles.isFirstLoad) {
      return const LoadingView(message: 'بنحمّل الأدوار…');
    }

    if (roles.hasFailed && roles.roles.isEmpty) {
      return ErrorView(message: roles.errorMessage!, onRetry: roles.retry);
    }

    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // عمود الأدوار (يمين في RTL)
        SizedBox(width: 288, child: RolesListPanel()),
        SizedBox(width: AppSpacing.xl),
        Expanded(child: PermissionsArea()),
      ],
    );
  }
}
