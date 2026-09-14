import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/stat_card.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/suppliers_list_controller.dart';

/// البطاقات الإحصائية فوق جدول الموردين.
///
/// الأرقام محسوبة على السيرفر على كل الموردين، مش على الصفحة المعروضة، ومفيش
/// نسب تغيّر لأن السيرفر مبيرجّعش فترة سابقة للموردين.
class SuppliersStatCards extends StatelessWidget {
  const SuppliersStatCards({super.key});

  @override
  Widget build(BuildContext context) {
    final SuppliersListController suppliers =
        context.watch<SuppliersListController>();

    return Row(
      children: <Widget>[
        Expanded(
          child: StatCard(
            title: 'الموردين المطابقين للفلتر',
            value: Fmt.count(suppliers.visibleCount),
            icon: Icons.local_shipping_outlined,
            iconColor: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'المستحقات على الشركة',
            value: Fmt.moneyRounded(suppliers.totalDue),
            icon: Icons.account_balance_outlined,
            iconColor: AppColors.danger,
            higherIsBetter: false,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'موردون عليهم مستحقات',
            value: Fmt.count(suppliers.dueSuppliersCount),
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.warning,
            higherIsBetter: false,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'موردون نشطون',
            value: Fmt.count(suppliers.activeCount),
            icon: Icons.verified_outlined,
            iconColor: AppColors.success,
          ),
        ),
      ],
    );
  }
}
