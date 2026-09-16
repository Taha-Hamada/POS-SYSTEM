import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/permission_groups.dart';

/// سطر صلاحية واحدة مع الـSwitch بتاعها.
class PermissionRow extends StatefulWidget {
  const PermissionRow({
    super.key,
    required this.permission,
    required this.value,
    required this.isLast,
    required this.onChanged,
  });

  final PermissionDef permission;
  final bool value;
  final bool isLast;

  /// null لما الدور مبيتعدّلش أو المستخدم مالوش صلاحية التعديل.
  final ValueChanged<bool>? onChanged;

  @override
  State<PermissionRow> createState() => _PermissionRowState();
}

class _PermissionRowState extends State<PermissionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onChanged != null;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: enabled ? () => widget.onChanged!(!widget.value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: _hovered && enabled
                ? AppColors.surfaceHover
                : AppColors.surface,
            border: widget.isLast
                ? null
                : const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.value
                      ? AppColors.success
                      : AppColors.borderStrong,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      widget.permission.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyMedium.copyWith(fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.permission.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Switch(
                value: widget.value,
                onChanged: widget.onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.accent,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.borderStrong,
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
