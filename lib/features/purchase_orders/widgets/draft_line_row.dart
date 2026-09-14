import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/create_purchase_order_controller.dart';
import '../models/draft_order_line.dart';
import 'draft_line_number_field.dart';
import 'draft_line_product_cell.dart';
import 'draft_line_stock_cell.dart';

/// صف صنف واحد في أمر الشراء الجديد.
class DraftLineRow extends StatefulWidget {
  const DraftLineRow({
    super.key,
    required this.line,
    required this.onRemove,
  });

  final DraftOrderLine line;
  final VoidCallback onRemove;

  @override
  State<DraftLineRow> createState() => _DraftLineRowState();
}

class _DraftLineRowState extends State<DraftLineRow> {
  late final TextEditingController _qtyController =
      TextEditingController(text: '${widget.line.quantity}');
  late final TextEditingController _costController =
      TextEditingController(text: widget.line.unitCost.toStringAsFixed(2));
  bool _hovered = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CreatePurchaseOrderController draft =
        context.read<CreatePurchaseOrderController>();
    final DraftOrderLine line = widget.line;

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
              child: DraftLineProductCell(line: line),
            ),
            Expanded(
              flex: 2,
              child: DraftLineStockCell(line: line),
            ),
            SizedBox(
              width: 120,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: DraftLineNumberField(
                  controller: _qtyController,
                  digitsOnly: true,
                  onChanged: (String v) =>
                      draft.setQuantity(line, int.tryParse(v) ?? 0),
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: DraftLineNumberField(
                  controller: _costController,
                  digitsOnly: false,
                  onChanged: (String v) =>
                      draft.setUnitCost(line, double.tryParse(v) ?? 0),
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Text(
                Fmt.money(line.total),
                textAlign: TextAlign.end,
                style: AppText.amountSm.copyWith(fontSize: 14),
              ),
            ),
            SizedBox(
              width: 44,
              child: IconButton(
                tooltip: 'حذف الصنف',
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.textMuted,
                hoverColor: AppColors.dangerSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
