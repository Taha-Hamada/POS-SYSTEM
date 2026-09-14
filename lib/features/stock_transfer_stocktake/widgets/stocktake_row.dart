import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/stocktake_controller.dart';
import '../models/stocktake_diff_style.dart';
import '../models/stocktake_line.dart';
import 'stocktake_actual_field.dart';
import 'stocktake_diff_badge.dart';
import 'stocktake_product_cell.dart';

/// صف واحد في جدول الجرد.
class StocktakeRow extends StatefulWidget {
  const StocktakeRow({super.key, required this.line});

  final StocktakeLine line;

  @override
  State<StocktakeRow> createState() => _StocktakeRowState();
}

class _StocktakeRowState extends State<StocktakeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final StocktakeController stocktake = context.read<StocktakeController>();
    final StocktakeLine line = widget.line;
    final StocktakeDiffStyle style = StocktakeDiffStyle.of(line);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surfaceHover : AppColors.surface,
          border: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 4,
              child: StocktakeProductCell(record: line.record),
            ),
            Expanded(
              flex: 2,
              child: Text(
                line.record.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Text(
                Fmt.count(line.systemQuantity),
                textAlign: TextAlign.center,
                style: AppText.amountSm.copyWith(fontSize: 14),
              ),
            ),
            SizedBox(
              width: 130,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: StocktakeActualField(
                  value: line.actualQuantity,
                  fillColor:
                      line.isCounted ? style.background : AppColors.surface,
                  onChanged: (int? v) =>
                      stocktake.setActualQuantity(line, v),
                ),
              ),
            ),
            SizedBox(
              width: 150,
              child: Center(
                child: StocktakeDiffBadge(line: line, style: style),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
