import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/roles_permissions_controller.dart';
import '../models/permission_groups.dart';
import 'permission_group_card.dart';
import 'role_banner.dart';

/// منطقة الصلاحيات: بانر الدور + كل أقسام الصلاحيات.
class PermissionsArea extends StatelessWidget {
  const PermissionsArea({super.key});

  @override
  Widget build(BuildContext context) {
    final RolesPermissionsController roles = context
        .watch<RolesPermissionsController>();

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: roles.fadeController,
        curve: Curves.easeOut,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const RoleBanner(),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final PermissionGroupDef group
                      in roles.groups) ...<Widget>[
                    PermissionGroupCard(group: group),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
