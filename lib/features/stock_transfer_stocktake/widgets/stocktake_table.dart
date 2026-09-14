import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/stocktake_controller.dart';
import '../models/stocktake_line.dart';
import 'stocktake_row.dart';
import 'stocktake_table_header.dart';

/// جدول أصناف الجرد.
class StocktakeTable extends StatelessWidget {
  const StocktakeTable({super.key});

  @override
  Widget build(BuildContext context) {
    final StocktakeController stocktake = context.watch<StocktakeController>();
    final List<StocktakeLine> lines = stocktake.visibleLines;

    return Container(
      decoration: AppDecorations.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          const StocktakeTableHeader(),
          Expanded(
            child: lines.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد أصناف مطابقة للبحث',
                      style: AppText.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: lines.length,
                    itemBuilder: (BuildContext context, int i) => StocktakeRow(
                      key: ValueKey<String>(
                        '${stocktake.branchId}_${lines[i].productId}',
                      ),
                      line: lines[i],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
