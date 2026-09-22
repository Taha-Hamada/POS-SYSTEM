import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/returnable_invoice.dart';
import '../../../theme/app_theme.dart';
import '../controllers/returns_controller.dart';
import '../models/return_line.dart';
import 'return_invoice_header.dart';
import 'return_lines_table_header.dart';
import 'return_row.dart';

/// بطاقة الفاتورة وأصنافها.
class ReturnLinesCard extends StatelessWidget {
  const ReturnLinesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ReturnsController returns = context.watch<ReturnsController>();
    final ReturnableInvoice invoice = returns.invoice!;
    final List<ReturnLine> lines = returns.lines;

    return Container(
      decoration: AppDecorations.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          ReturnInvoiceHeader(invoice: invoice),
          const ReturnLinesTableHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double tableMinWidth = 760;
                final bool needHorizontalScroll =
                    constraints.maxWidth < tableMinWidth;

                return needHorizontalScroll
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableMinWidth,
                          child: ListView.builder(
                            itemCount: lines.length,
                            itemBuilder: (BuildContext context, int i) => ReturnRow(
                              key: ValueKey<String>(lines[i].source.invoiceLineId),
                              line: lines[i],
                              index: i,
                              isLast: i == lines.length - 1,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: lines.length,
                        itemBuilder: (BuildContext context, int i) => ReturnRow(
                          key: ValueKey<String>(lines[i].source.invoiceLineId),
                          line: lines[i],
                          index: i,
                          isLast: i == lines.length - 1,
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
