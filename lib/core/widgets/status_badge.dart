import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum StatusTone { success, warning, danger, info, neutral, accent }

/// Badge صغير ملوّن حسب الحالة — نفس الشكل في كل الجداول والبطاقات.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.showDot = true,
    this.compact = false,
  });

  /// Badge جاهز لحالة المخزون
  factory StatusBadge.stock({
    required num stock,
    required num minStock,
    bool compact = false,
  }) {
    if (stock <= 0) {
      return StatusBadge(
        label: 'نفد المخزون',
        tone: StatusTone.danger,
        compact: compact,
      );
    }
    if (stock <= minStock) {
      return StatusBadge(
        label: 'مخزون منخفض',
        tone: StatusTone.warning,
        compact: compact,
      );
    }
    return StatusBadge(
      label: 'متوفر',
      tone: StatusTone.success,
      compact: compact,
    );
  }

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool showDot;
  final bool compact;

  Color get _foreground => switch (tone) {
        StatusTone.success => AppColors.success,
        StatusTone.warning => AppColors.warning,
        StatusTone.danger => AppColors.danger,
        StatusTone.info => AppColors.info,
        StatusTone.accent => AppColors.accent,
        StatusTone.neutral => AppColors.textSecondary,
      };

  Color get _background => switch (tone) {
        StatusTone.success => AppColors.successSoft,
        StatusTone.warning => AppColors.warningSoft,
        StatusTone.danger => AppColors.dangerSoft,
        StatusTone.info => AppColors.infoSoft,
        StatusTone.accent => AppColors.accentSoft,
        StatusTone.neutral => AppColors.neutralSoft,
      };

  @override
  Widget build(BuildContext context) {
    final Color fg = _foreground;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md - 2,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: compact ? 11 : 13, color: fg),
            const SizedBox(width: 5),
          ] else if (showDot) ...<Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: fg,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
