import 'package:flutter/material.dart';

import '../../../core/models/employee.dart';
import '../../../core/models/user_role.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../models/permission_groups.dart';

/// نتيجة تعديل صلاحيات موظف: الزيادة والاستثناءات فوق باقة الدور.
typedef PermissionOverrides = ({Set<String> granted, Set<String> revoked});

/// صلاحيات موظف بعينه فوق دوره. بيرجّع التعديل أو null لو اتلغى.
Future<PermissionOverrides?> showEmployeePermissionsDialog(
  BuildContext context, {
  required Employee employee,
  required Set<String> rolePermissions,
  required List<String> allPermissions,
}) {
  return showDialog<PermissionOverrides>(
    context: context,
    builder: (_) => EmployeePermissionsDialog(
      employee: employee,
      rolePermissions: rolePermissions,
      allPermissions: allPermissions,
    ),
  );
}

class EmployeePermissionsDialog extends StatefulWidget {
  const EmployeePermissionsDialog({
    super.key,
    required this.employee,
    required this.rolePermissions,
    required this.allPermissions,
  });

  final Employee employee;

  /// صلاحيات دور الموظف زي ما هي على السيرفر دلوقتي.
  final Set<String> rolePermissions;
  final List<String> allPermissions;

  @override
  State<EmployeePermissionsDialog> createState() =>
      _EmployeePermissionsDialogState();
}

class _EmployeePermissionsDialogState extends State<EmployeePermissionsDialog> {
  late final Set<String> _granted = <String>{
    ...widget.employee.grantedPermissions,
  };
  late final Set<String> _revoked = <String>{
    ...widget.employee.revokedPermissions,
  };

  /// مدير النظام بياخد كل حاجة على السيرفر، فالاستثناءات مالهاش معنى معاه.
  bool get _locked => widget.employee.role == UserRole.admin.apiValue;

  bool _isOn(String permission) => widget.rolePermissions.contains(permission)
      ? !_revoked.contains(permission)
      : _granted.contains(permission);

  void _toggle(String permission, bool value) {
    setState(() {
      if (widget.rolePermissions.contains(permission)) {
        // الصلاحية جاية من الدور: القفل بيتسجل كاستثناء.
        value ? _revoked.remove(permission) : _revoked.add(permission);
        _granted.remove(permission);
        return;
      }

      value ? _granted.add(permission) : _granted.remove(permission);
      _revoked.remove(permission);
    });
  }

  int get _changes => _granted.length + _revoked.length;

  @override
  Widget build(BuildContext context) {
    final List<PermissionGroupDef> groups = permissionGroupsFor(
      widget.allPermissions,
    );

    return AlertDialog(
      title: Text('صلاحيات ${widget.employee.name}'),
      content: SizedBox(
        width: 620,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _locked
                  ? 'مدير النظام عنده كل الصلاحيات، ومينفعش تتسحب منه.'
                  : 'دوره «${widget.employee.roleLabel}» بيديله باقة صلاحيات. '
                        'هنا بتزوّد أو تسحب لحسابه هو بس، من غير ما تأثر على '
                        'باقي اللي على نفس الدور.',
              style: AppText.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                children: <Widget>[
                  for (final PermissionGroupDef group in groups) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: AppSpacing.xs,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            group.icon,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(group.title, style: AppText.label),
                        ],
                      ),
                    ),
                    for (final PermissionDef p in group.permissions) _row(p),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        if (_changes > 0 && !_locked)
          TextButton(
            onPressed: () => setState(() {
              _granted.clear();
              _revoked.clear();
            }),
            child: const Text('رجّع لصلاحيات الدور'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        PrimaryButton(
          label: 'حفظ',
          size: AppButtonSize.small,
          onPressed: _locked
              ? null
              : () => Navigator.of(
                  context,
                ).pop((granted: _granted, revoked: _revoked)),
        ),
      ],
    );
  }

  Widget _row(PermissionDef permission) {
    final bool fromRole = widget.rolePermissions.contains(permission.value);
    final bool on = _isOn(permission.value);

    final (String, StatusTone)? tag = _revoked.contains(permission.value)
        ? ('مسحوبة منه', StatusTone.danger)
        : _granted.contains(permission.value)
        ? ('مضافة له', StatusTone.accent)
        : fromRole
        ? ('من الدور', StatusTone.neutral)
        : null;

    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      value: _locked || on,
      onChanged: _locked
          ? null
          : (bool value) => _toggle(permission.value, value),
      title: Row(
        children: <Widget>[
          Flexible(child: Text(permission.label, style: AppText.body)),
          if (tag != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            StatusBadge(label: tag.$1, tone: tag.$2, compact: true),
          ],
        ],
      ),
      subtitle: Text(permission.description, style: AppText.caption),
    );
  }
}
