import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/roles_permissions_controller.dart';
import '../models/role_catalog.dart';
import 'role_employees_chip.dart';

/// بانر الدور المختار فوق أقسام الصلاحيات.
class RoleBanner extends StatelessWidget {
  const RoleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final RolesPermissionsController roles = context
        .watch<RolesPermissionsController>();
    final RoleInfo? role = roles.role;

    if (role == null) return const SizedBox.shrink();

    final String description = !role.editable
        ? 'صلاحيات كاملة على كل النظام ومش بتتعدّل'
        : !roles.canEdit
        ? '${role.role?.description ?? ''} — عرض فقط'
        : role.role?.description ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.22),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(
              role.role?.icon ?? Icons.shield_outlined,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'صلاحيات دور: ${role.label}',
                  style: AppText.sectionTitle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  role.customized ? '$description • باقة معدّلة' : description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textOnDarkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${roles.enabledCount} / ${roles.totalPermissions}',
                style: AppText.amountLg.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 2),
              const Text(
                'صلاحية مفعّلة',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textOnDarkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          RoleEmployeesChip(count: role.usersCount),
        ],
      ),
    );
  }
}
