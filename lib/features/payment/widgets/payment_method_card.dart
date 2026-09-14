import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../core/models/payment_method.dart';

/// كارت طريقة دفع واحدة جوه شبكة الاختيار.
class PaymentMethodCard extends StatefulWidget {
  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.selected,
    required this.used,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;

  /// اتسجّلت بيها دفعة قبل كده — بيظهر عليها علامة صح.
  final bool used;
  final VoidCallback onTap;

  @override
  State<PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<PaymentMethodCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.selected;
    final Color accent = widget.method.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: active
                ? AppColors.accentSoft
                : _hovered
                    ? AppColors.surfaceAlt
                    : AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: active
                  ? AppColors.accent
                  : _hovered
                      ? AppColors.borderStrong
                      : AppColors.border,
              width: active ? 2 : 1,
            ),
            boxShadow: active || _hovered ? AppShadows.soft : null,
          ),
          child: Stack(
            children: <Widget>[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            active ? accent : accent.withValues(alpha: 0.10),
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: Icon(
                        widget.method.icon,
                        size: 23,
                        color: active ? Colors.white : accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.method.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                        color:
                            active ? AppColors.accent : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.used)
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.success.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
