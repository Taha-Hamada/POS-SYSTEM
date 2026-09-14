import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/stat_card.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/customers_list_controller.dart';

/// البطاقات الإحصائية الأربعة فوق جدول العملاء.
class CustomersStatCards extends StatelessWidget {
  const CustomersStatCards({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomersListController customers =
        context.watch<CustomersListController>();

    return Row(
      children: <Widget>[
        Expanded(
          child: StatCard(
            title: 'إجمالي العملاء',
            value: Fmt.count(customers.allCustomers.length),
            icon: Icons.people_alt_outlined,
            iconColor: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'إجمالي المديونيات',
            value: Fmt.moneyRounded(customers.totalDebt),
            icon: Icons.credit_card_off_outlined,
            iconColor: AppColors.danger,
            higherIsBetter: false,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'عملاء ذهبيون',
            value: Fmt.count(customers.tierCount('gold')),
            icon: Icons.workspace_premium_outlined,
            iconColor: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'إجمالي المشتريات',
            value: Fmt.moneyRounded(customers.totalPurchases),
            icon: Icons.shopping_bag_outlined,
            iconColor: AppColors.success,
          ),
        ),
      ],
    );
  }
}
