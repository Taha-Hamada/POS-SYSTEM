import 'package:flutter/material.dart';

import '../../../core/models/branch.dart';
import '../../../theme/app_theme.dart';

enum _BranchAction { toggleOpen, deactivate }

/// رأس بطاقة الفرع: الأيقونة والاسم وحالة الفتح وقايمة الإجراءات.
class BranchCardHeader extends StatelessWidget {
  const BranchCardHeader({
    super.key,
    required this.branch,
    this.onToggleOpen,
    this.onDeactivate,
  });

  final Branch branch;
  final VoidCallback? onToggleOpen;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final Branch b = branch;

    // الفرع الرئيسي مينفعش يتعطّل، فالاختيار مابيظهرش أصلًا.
    final bool canDeactivate = onDeactivate != null && !b.isMain;
    final bool hasActions = onToggleOpen != null || canDeactivate;

    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: b.isMain
                  ? <Color>[AppColors.accent, const Color(0xFF8B5CF6)]
                  : <Color>[AppColors.primaryLight, AppColors.primary],
            ),
            borderRadius: AppRadius.mdAll,
          ),
          child: Icon(
            b.isMain ? Icons.star_rounded : Icons.storefront_rounded,
            size: 23,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  // النقطة الملونة: أخضر = مفتوح، رمادي = مغلق
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: b.isOpen ? AppColors.success : AppColors.textMuted,
                      shape: BoxShape.circle,
                      boxShadow: b.isOpen
                          ? <BoxShadow>[
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${b.isOpen ? 'مفتوح الآن' : 'مغلق'} • ${b.code}',
                style: AppText.caption.copyWith(
                  fontSize: 11.5,
                  color: b.isOpen ? AppColors.success : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (hasActions)
          PopupMenuButton<_BranchAction>(
            tooltip: 'إجراءات الفرع',
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
            onSelected: (_BranchAction action) => switch (action) {
              _BranchAction.toggleOpen => onToggleOpen?.call(),
              _BranchAction.deactivate => onDeactivate?.call(),
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<_BranchAction>>[
                  if (onToggleOpen != null)
                    PopupMenuItem<_BranchAction>(
                      value: _BranchAction.toggleOpen,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            b.isOpen
                                ? Icons.lock_outline_rounded
                                : Icons.lock_open_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(b.isOpen ? 'قفل الفرع' : 'فتح الفرع'),
                        ],
                      ),
                    ),
                  if (canDeactivate)
                    const PopupMenuItem<_BranchAction>(
                      value: _BranchAction.deactivate,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.block_rounded,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: AppSpacing.md),
                          Text(
                            'تعطيل الفرع',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                ],
          ),
      ],
    );
  }
}
