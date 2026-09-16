import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/customer.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/loyalty_controller.dart';
import 'loyalty_points_cell.dart';
import 'loyalty_rank_badge.dart';
import 'loyalty_tier_pill.dart';

/// جدول أعلى العملاء نقاطًا.
class LoyaltyLeaderboard extends StatelessWidget {
  const LoyaltyLeaderboard({super.key});

  static const List<AppTableColumn> _columns = <AppTableColumn>[
    AppTableColumn('الترتيب', fixedWidth: 90),
    AppTableColumn('العميل', size: ColumnSize.L),
    AppTableColumn('المستوى', size: ColumnSize.S),
    AppTableColumn('إجمالي المشتريات', size: ColumnSize.M, numeric: true),
    AppTableColumn('قيمة النقاط', size: ColumnSize.S, numeric: true),
    AppTableColumn('رصيد النقاط', size: ColumnSize.M, numeric: true),
  ];

  List<Widget> _cells(LoyaltyController loyalty, Customer c, int index) {
    return <Widget>[
      LoyaltyRankBadge(rank: index + 1),
      TableCells.avatarName(
        c.name,
        c.initials,
        color: AppColors.accent,
        subtitle: c.phone,
      ),
      LoyaltyTierPill(tierKey: c.tier, name: loyalty.tierNameOf(c)),
      TableCells.amount(c.totalPurchases),
      Text(
        Fmt.money(loyalty.pointsValue(c)),
        style: AppText.amountSm.copyWith(color: AppColors.success),
      ),
      LoyaltyPointsCell(points: c.points),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final LoyaltyController loyalty = context.watch<LoyaltyController>();
    final List<Customer> customers = loyalty.topCustomers;

    return SizedBox(
      height: 460,
      child: AppDataTable(
        title: 'أعلى العملاء نقاطًا',
        subtitle: 'ترتيب تنازلي حسب رصيد النقاط الحالي',
        minWidth: 900,
        rowHeight: 62,
        emptyMessage: 'لا يوجد عملاء لديهم نقاط',
        emptyIcon: Icons.stars_outlined,
        columns: _columns,
        rows: <AppTableRow>[
          for (int i = 0; i < customers.length; i++)
            AppTableRow(cells: _cells(loyalty, customers[i], i)),
        ],
        footer: Row(
          children: <Widget>[
            Text('نقاط العملاء المعروضين', style: AppText.caption),
            const Spacer(),
            Text(
              Fmt.count(loyalty.totalGrantedPoints),
              style: AppText.amountMd.copyWith(color: AppColors.warning),
            ),
          ],
        ),
      ),
    );
  }
}
