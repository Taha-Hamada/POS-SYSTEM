import 'package:flutter/material.dart';

import '../../../core/models/promotion.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../models/promotion_status_tone.dart';
import '../models/promotion_type_color.dart';
import 'promotion_date_range_row.dart';
import 'promotion_duration_bar.dart';
import 'promotion_type_badge.dart';
import 'promotion_value_row.dart';

enum _PromotionAction { edit, toggleActive }

/// بطاقة عرض واحد في الشبكة.
class PromotionCard extends StatefulWidget {
  const PromotionCard({
    super.key,
    required this.promotion,
    this.onEdit,
    this.onToggleActive,
  });

  final Promotion promotion;

  /// null لو المستخدم مالوش إدارة العروض.
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;

  @override
  State<PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<PromotionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Promotion p = widget.promotion;
    final PromotionStatus status = p.status;
    final bool faded =
        status == PromotionStatus.expired || status == PromotionStatus.stopped;

    return MouseRegion(
      cursor: widget.onEdit != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: _hovered
                  ? p.type.color.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
            boxShadow: _hovered ? AppShadows.lifted : AppShadows.soft,
          ),
          child: Opacity(
            opacity: faded ? 0.72 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    PromotionTypeBadge(type: p.type),
                    const Spacer(),
                    StatusBadge(
                      label: status.label,
                      tone: status.tone,
                      compact: true,
                    ),
                    if (widget.onEdit != null || widget.onToggleActive != null)
                      _menu(p),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  p.scopeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontSize: 12),
                ),
                const Spacer(),
                PromotionValueRow(promotion: p),
                const SizedBox(height: AppSpacing.md),
                PromotionDurationBar(promotion: p),
                const SizedBox(height: AppSpacing.sm),
                PromotionDateRangeRow(promotion: p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu(Promotion p) {
    return SizedBox(
      width: 32,
      height: 28,
      child: PopupMenuButton<_PromotionAction>(
        padding: EdgeInsets.zero,
        tooltip: 'إجراءات العرض',
        icon: const Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: AppColors.textMuted,
        ),
        onSelected: (_PromotionAction action) => switch (action) {
          _PromotionAction.edit => widget.onEdit?.call(),
          _PromotionAction.toggleActive => widget.onToggleActive?.call(),
        },
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<_PromotionAction>>[
              if (widget.onEdit != null)
                const PopupMenuItem<_PromotionAction>(
                  value: _PromotionAction.edit,
                  child: Text('تعديل العرض'),
                ),
              if (widget.onToggleActive != null)
                PopupMenuItem<_PromotionAction>(
                  value: _PromotionAction.toggleActive,
                  child: Text(
                    p.isActive ? 'إيقاف العرض' : 'تفعيل العرض',
                    style: TextStyle(
                      color: p.isActive ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ),
            ],
      ),
    );
  }
}
