import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// تبويب فاتورة واحدة في شريط الفواتير المفتوحة.
class InvoiceTab extends StatefulWidget {
  const InvoiceTab({
    super.key,
    required this.number,
    required this.itemsCount,
    required this.selected,
    required this.onTap,
    this.onClose,
  });

  final int number;
  final double itemsCount;
  final bool selected;
  final VoidCallback onTap;

  /// null = التبويب الأخير، مينفعش يتقفل.
  final VoidCallback? onClose;

  @override
  State<InvoiceTab> createState() => _InvoiceTabState();
}

class _InvoiceTabState extends State<InvoiceTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          padding: EdgeInsetsDirectional.only(
            start: AppSpacing.md,
            end: widget.onClose == null ? AppSpacing.md : 4,
          ),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : _hovered
                    ? AppColors.surfaceAlt
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm + 2),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'ف${widget.number}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
              if (widget.itemsCount > 0) ...<Widget>[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.20)
                        : AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    Fmt.qty(widget.itemsCount),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.accent,
                    ),
                  ),
                ),
              ],
              if (widget.onClose != null) ...<Widget>[
                const SizedBox(width: 2),
                IconButton(
                  tooltip: 'إغلاق الفاتورة',
                  onPressed: widget.onClose,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: active
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
