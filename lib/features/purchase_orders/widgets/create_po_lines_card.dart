import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/create_purchase_order_controller.dart';
import '../models/draft_order_line.dart';
import 'create_po_lines_empty.dart';
import 'create_po_lines_header.dart';
import 'create_po_lines_toolbar.dart';
import 'draft_line_row.dart';

/// بطاقة أصناف الأمر: شريط الأدوات + رأس الجدول + الصفوف.
class CreatePoLinesCard extends StatelessWidget {
  const CreatePoLinesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final CreatePurchaseOrderController draft =
        context.watch<CreatePurchaseOrderController>();
    final List<DraftOrderLine> lines = draft.lines;

    return Container(
      decoration: AppDecorations.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          const CreatePoLinesToolbar(),
          const CreatePoLinesHeader(),
          Expanded(
            child: lines.isEmpty
                ? const CreatePoLinesEmpty()
                : ListView.builder(
                    itemCount: lines.length,
                    itemBuilder: (BuildContext context, int i) => DraftLineRow(
                      key: ValueKey<String>(lines[i].productId),
                      line: lines[i],
                      onRemove: () => draft.removeLineAt(i),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
