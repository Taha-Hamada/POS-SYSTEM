import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/returns_controller.dart';
import '../models/return_accent.dart';
import '../models/return_line.dart';
import 'return_product_cell.dart';
import 'return_quantity_field.dart';

/// صف صنف واحد في جدول المرتجع.
class ReturnRow extends StatefulWidget {
  const ReturnRow({
    super.key,
    required this.line,
    required this.index,
    required this.isLast,
  });

  final ReturnLine line;

  /// ترتيب السطر في الجدول — بيتمرّر لخلية الصنف عشان لونها.
  final int index;

  final bool isLast;

  @override
  State<ReturnRow> createState() => _ReturnRowState();
}

class _ReturnRowState extends State<ReturnRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ReturnsController returns = context.read<ReturnsController>();
    final ReturnLine line = widget.line;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => returns.toggleLine(line),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: line.selected
                ? kReturnAccent.withValues(alpha: 0.05)
                : _hovered
                    ? AppColors.surfaceHover
                    : AppColors.surface,
            border: widget.isLast
                ? null
                : const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 720;

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SizedBox(
                          width: 48,
                          child: Checkbox(
                            value: line.selected,
                            activeColor: kReturnAccent,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (bool? v) =>
                                returns.setLineSelected(line, v ?? false),
                          ),
                        ),
                        Expanded(
                          child: ReturnProductCell(
                            line: line,
                            index: widget.index,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.spaceBetween,
                      children: <Widget>[
                        SizedBox(
                          width: 90,
                          child: Text(
                            'مباعة: ${Fmt.count(line.maxQuantity)}',
                            style: AppText.amountSm.copyWith(fontSize: 13),
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: ReturnQuantityField(
                            initialQuantity: line.returnQuantity,
                            enabled: line.selected,
                            onChanged: (double v) =>
                                returns.setReturnQuantity(line, v),
                          ),
                        ),
                        Text(
                          line.selected ? Fmt.money(line.refundAmount) : '—',
                          style: AppText.amountSm.copyWith(
                            fontSize: 13.5,
                            color: line.selected
                                ? kReturnAccent
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 760),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 48,
                      child: Checkbox(
                        value: line.selected,
                        activeColor: kReturnAccent,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (bool? v) =>
                            returns.setLineSelected(line, v ?? false),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: ReturnProductCell(line: line, index: widget.index),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text(
                        Fmt.count(line.maxQuantity),
                        textAlign: TextAlign.center,
                        style: AppText.amountSm.copyWith(fontSize: 13.5),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: ReturnQuantityField(
                          initialQuantity: line.returnQuantity,
                          enabled: line.selected,
                          onChanged: (double v) =>
                              returns.setReturnQuantity(line, v),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        line.selected ? Fmt.money(line.refundAmount) : '—',
                        textAlign: TextAlign.end,
                        style: AppText.amountSm.copyWith(
                          fontSize: 13.5,
                          color: line.selected
                              ? kReturnAccent
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
