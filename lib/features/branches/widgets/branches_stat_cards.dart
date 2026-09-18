import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/stat_card.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/branches_controller.dart';
import '../models/branch_stats.dart';

/// البطاقات الإحصائية الأربعة فوق شبكة الفروع.
class BranchesStatCards extends StatelessWidget {
  const BranchesStatCards({super.key});

  @override
  Widget build(BuildContext context) {
    final BranchesTotals totals = context.select(
      (BranchesController b) => b.totals,
    );

    return Row(
      children: <Widget>[
        Expanded(
          child: StatCard(
            title: 'عدد الفروع',
            value: Fmt.count(totals.branches),
            icon: Icons.store_outlined,
            iconColor: AppColors.accent,
            changeLabel: '${Fmt.count(totals.open)} مفتوح الآن',
            changePercent: 0,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'مبيعات اليوم — كل الفروع',
            value: Fmt.moneyRounded(totals.todaySales),
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.success,
            changePercent: totals.todayChange,
            changeLabel: 'مقارنة بأمس',
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'مبيعات الشهر',
            value: Fmt.moneyRounded(totals.monthSales),
            icon: Icons.calendar_month_outlined,
            iconColor: AppColors.warning,
            changePercent: totals.monthChange,
            changeLabel: 'مقارنة بنفس الفترة من الشهر الماضي',
          ),
        ),
      ],
    );
  }
}
