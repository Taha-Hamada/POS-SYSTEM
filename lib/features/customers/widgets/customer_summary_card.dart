import 'package:flutter/material.dart';

import '../../../core/widgets/profile_summary_card.dart';
import '../../../core/models/customer.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// بطاقة ملخّص العميل أعلى الملف.
class CustomerSummaryCard extends StatelessWidget {
  const CustomerSummaryCard({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final Customer c = customer;
    final bool isDebtor = c.balance < 0;

    return ProfileSummaryCard(
      name: c.name,
      subtitle: '${Fmt.count(c.ordersCount)} فاتورة • '
          '${c.lastVisitAt == null ? 'مجاش لسه' : 'آخر زيارة ${Fmt.date(c.lastVisitAt!)}'}',
      meta: <(IconData, String)>[
        (Icons.phone_outlined, c.phone),
        (Icons.mail_outline_rounded, c.email ?? '—'),
      ],
      stats: <ProfileStat>[
        ProfileStat(
          label: isDebtor ? 'الرصيد المستحق عليه' : 'الرصيد',
          value: Fmt.money(c.balance.abs()),
          color: isDebtor
              ? AppColors.danger
              : c.balance > 0
                  ? AppColors.success
                  : AppColors.textPrimary,
          icon: Icons.account_balance_wallet_outlined,
          big: true,
        ),
        ProfileStat(
          label: 'إجمالي المشتريات',
          value: Fmt.moneyRounded(c.totalPurchases),
          icon: Icons.shopping_bag_outlined,
        ),
      ],
    );
  }
}
