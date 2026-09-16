import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/roles_permissions_controller.dart';
import '../models/role_catalog.dart';

/// الشريط السفلي الثابت: حالة الحفظ وأزرار الاستعادة والحفظ.
class RolesPermissionsFooter extends StatelessWidget {
  const RolesPermissionsFooter({super.key});

  Future<void> _save(BuildContext context) async {
    final RolesPermissionsController roles = context
        .read<RolesPermissionsController>();
    final String roleName = roles.role?.label ?? '';

    final String? error = await roles.save();
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      error ?? 'اتحفظت صلاحيات دور «$roleName»',
      isError: error != null,
      width: 460,
    );
  }

  Future<void> _reset(BuildContext context) async {
    final String? error = await context
        .read<RolesPermissionsController>()
        .resetToDefaults();
    if (!context.mounted || error == null) return;

    showAppSnackBar(context, error, isError: true, width: 460);
  }

  @override
  Widget build(BuildContext context) {
    final RolesPermissionsController roles = context
        .watch<RolesPermissionsController>();
    final RoleInfo? role = roles.role;

    // مفيش حاجة تتحفظ لو المستخدم معندوش إدارة الموظفين.
    if (!roles.canEdit || role == null) return const SizedBox.shrink();

    final bool dirty = roles.dirty;
    final bool busy = roles.isLoading;

    final String status = !role.editable
        ? 'صلاحيات «${role.label}» كاملة ومش بتتعدّل'
        : dirty
        ? 'يوجد تغييرات غير محفوظة على دور «${role.label}»'
        : 'كل التغييرات محفوظة';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(
            dirty
                ? Icons.edit_note_rounded
                : Icons.check_circle_outline_rounded,
            size: 18,
            color: dirty ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              status,
              style: AppText.caption.copyWith(fontSize: 12.5),
            ),
          ),
          SecondaryButton(
            label: 'استعادة الافتراضي',
            icon: Icons.restart_alt_rounded,
            size: AppButtonSize.large,
            onPressed: roles.canReset && !busy ? () => _reset(context) : null,
          ),
          const SizedBox(width: AppSpacing.md),
          PrimaryButton(
            label: busy ? 'جاري الحفظ…' : 'حفظ التغييرات',
            icon: Icons.save_outlined,
            size: AppButtonSize.large,
            onPressed: dirty && !busy ? () => _save(context) : null,
          ),
        ],
      ),
    );
  }
}
