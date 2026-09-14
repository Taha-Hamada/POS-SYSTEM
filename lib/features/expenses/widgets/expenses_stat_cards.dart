import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/stat_card.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/expenses_controller.dart';

/// البطاقات الإحصائية فوق جدول المصروفات.
///
/// كل رقم هنا محسوب على السيرفر على كل المصروفات المطابقة، مش على الصفحة
/// المعروضة، ومفيش نسب تغيّر لأن مسار الملخّص مبيرجّعش فترة سابقة.
class ExpensesStatCards extends StatelessWidget {
  const ExpensesStatCards({super.key});

  @override
  Widget build(BuildContext context) {
    final ExpensesController expenses = context.watch<ExpensesController>();

    return Row(
      children: <Widget>[
        Expanded(
          child: StatCard(
            title: 'إجمالي المصروفات المطابقة',
            value: Fmt.moneyRounded(expenses.visibleTotal),
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.danger,
            higherIsBetter: false,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'مصروفات الشهر الحالي',
            value: Fmt.moneyRounded(expenses.monthTotal),
            icon: Icons.calendar_month_outlined,
            iconColor: AppColors.warning,
            higherIsBetter: false,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'بانتظار الاعتماد',
            value: Fmt.moneyRounded(expenses.pendingTotal),
            icon: Icons.pending_actions_outlined,
            iconColor: AppColors.accent,
            higherIsBetter: false,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'عدد المصروفات',
            value: Fmt.count(expenses.visibleCount),
            icon: Icons.list_alt_rounded,
            iconColor: AppColors.info,
          ),
        ),
      ],
    );
  }
}
