import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/roles_permissions_controller.dart';
import '../models/permission_groups.dart';

/// عنوان قسم صلاحيات مع عدّاده وزرار تفعيل/إلغاء الكل.
class PermissionGroupHeader extends StatelessWidget {
  const PermissionGroupHeader({super.key, required this.group});

  final PermissionGroupDef group;

  @override
  Widget build(BuildContext context) {
    final RolesPermissionsController roles = context
        .watch<RolesPermissionsController>();
    final bool allOn = roles.isGroupAllOn(group);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(group.icon, size: 17, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(group.title, style: AppText.cardTitle),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${roles.enabledCountIn(group)} / ${group.permissions.length}',
              style: AppText.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          if (roles.editable)
            TextButton.icon(
              onPressed: () => roles.toggleGroup(group, !allOn),
              icon: Icon(
                allOn ? Icons.remove_done_rounded : Icons.done_all_rounded,
                size: 16,
              ),
              label: Text(allOn ? 'إلغاء الكل' : 'تفعيل الكل'),
            ),
        ],
      ),
    );
  }
}
