import 'package:flutter/material.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/customer_entries.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// جدول سجل كسب واستبدال النقاط.
class LoyaltyHistoryTable extends StatelessWidget {
  const LoyaltyHistoryTable({super.key, required this.entries});

  final List<LoyaltyEntry> entries;

  @override
  Widget build(BuildContext context) {
    return AppDataTable(
      title: 'سجل النقاط',
      subtitle: 'كل عمليات الكسب والاستبدال',
      minWidth: 620,
      rowHeight: 58,
      emptyMessage: 'لا توجد حركات نقاط لهذا العميل',
      emptyIcon: Icons.stars_outlined,
      columns: const <AppTableColumn>[
        AppTableColumn('التاريخ', size: ColumnSize.S),
        AppTableColumn('العملية', size: ColumnSize.L),
        AppTableColumn('النوع', size: ColumnSize.S),
        AppTableColumn('النقاط', size: ColumnSize.S, numeric: true),
      ],
      rows: <AppTableRow>[
        for (final LoyaltyEntry e in entries)
          AppTableRow(
            cells: <Widget>[
              Text(
                Fmt.date(e.date),
                style: AppText.body.copyWith(fontSize: 12.5),
              ),
              Text(
                e.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(fontSize: 13),
              ),
              StatusBadge(
                label: e.typeLabel,
                tone: e.isEarn
                    ? StatusTone.success
                    : StatusTone.warning,
                compact: true,
                showDot: false,
              ),
              Text(
                '${e.points > 0 ? '+' : ''}${Fmt.count(e.points)}',
                style: AppText.amountSm.copyWith(
                  color: e.points > 0
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
