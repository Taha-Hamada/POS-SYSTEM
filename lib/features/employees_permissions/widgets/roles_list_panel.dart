import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/roles_permissions_controller.dart';
import '../models/role_catalog.dart';
import 'role_card.dart';

/// عمود الأدوار (يمين في RTL).
class RolesListPanel extends StatelessWidget {
  const RolesListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final RolesPermissionsController roles = context
        .watch<RolesPermissionsController>();

    return Container(
      decoration: AppDecorations.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('الأدوار', style: AppText.cardTitle),
                const Spacer(),
                Text(Fmt.count(roles.roles.length), style: AppText.caption),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: roles.roles.length,
              itemBuilder: (BuildContext context, int i) {
                final RoleInfo role = roles.roles[i];
                return RoleCard(
                  role: role,
                  selected: role.value == roles.selectedRoleId,
                  enabledCount: roles.enabledCountForRole(role.value),
                  totalCount: roles.totalPermissions,
                  dirty: roles.isDirty(role.value),
                  onTap: () => roles.selectRole(role.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
