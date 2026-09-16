import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/role_catalog.dart';
import 'role_permissions_progress.dart';

/// كارت دور واحد في القائمة اليمين.
class RoleCard extends StatefulWidget {
  const RoleCard({
    super.key,
    required this.role,
    required this.selected,
    required this.enabledCount,
    required this.totalCount,
    required this.onTap,
    this.dirty = false,
  });

  final RoleInfo role;
  final bool selected;
  final int enabledCount;
  final int totalCount;
  final VoidCallback onTap;

  /// فيه تعديلات على الدور ده لسه متحفظتش.
  final bool dirty;

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.selected;
    final RoleInfo role = widget.role;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          decoration: BoxDecoration(
            color: active
                ? AppColors.accentSoft
                : _hovered
                ? AppColors.surfaceAlt
                : AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: active
                  ? AppColors.accent
                  : _hovered
                  ? AppColors.borderStrong
                  : AppColors.border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.accent
                          : AppColors.accent.withValues(alpha: 0.10),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Icon(
                      role.role?.icon ?? Icons.shield_outlined,
                      size: 18,
                      color: active ? Colors.white : AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      role.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle.copyWith(
                        fontSize: 14,
                        color: active
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (widget.dirty)
                    const Tooltip(
                      message: 'تعديلات غير محفوظة',
                      child: Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                    )
                  else if (!role.editable)
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    )
                  else if (active)
                    const Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: AppColors.accent,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                role.role?.description ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(fontSize: 11.5, height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              RolePermissionsProgress(
                enabledCount: widget.enabledCount,
                totalCount: widget.totalCount,
                active: active,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
