import 'package:flutter/material.dart';

import '../../../core/models/supplier.dart';
import '../../../core/widgets/profile_summary_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/supplier_profile_controller.dart';

/// بطاقة ملخّص المورد أعلى الملف.
class SupplierSummaryCard extends StatelessWidget {
  const SupplierSummaryCard({
    super.key,
    required this.supplier,
    required this.profile,
  });

  final Supplier supplier;
  final SupplierProfileController profile;

  @override
  Widget build(BuildContext context) {
    final Supplier s = supplier;
    final int productsCount = profile.products.length;

    return ProfileSummaryCard(
      name: s.name,
      subtitle: s.contactPerson.isEmpty
          ? 'مفيش مسؤول تواصل مسجّل'
          : 'مسؤول التواصل: ${s.contactPerson}',
      avatarIcon: Icons.storefront_rounded,
      avatarColor: AppColors.accent,
      badge: StatusBadge(
        label: s.isActive ? 'نشط' : 'موقوف',
        tone: s.isActive ? StatusTone.success : StatusTone.neutral,
      ),
      meta: <(IconData, String)>[
        (Icons.phone_outlined, s.phone),
        if (s.email.isNotEmpty) (Icons.mail_outline_rounded, s.email),
        (Icons.inventory_2_outlined, '$productsCount صنف موّرد'),
        if (s.paymentTermDays > 0)
          (Icons.schedule_rounded, 'مهلة سداد ${s.paymentTermDays} يوم'),
      ],
      stats: <ProfileStat>[
        ProfileStat(
          label: 'الرصيد المستحق للمورد',
          value: Fmt.money(s.balanceDue),
          color: s.hasDue ? AppColors.danger : AppColors.success,
          icon: Icons.account_balance_wallet_outlined,
          big: true,
        ),
        ProfileStat(
          label: 'أوامر التوريد المكتملة',
          value: Fmt.count(s.ordersCount),
          icon: Icons.receipt_long_outlined,
        ),
        ProfileStat(
          label: 'إجمالي المشتريات',
          value: Fmt.moneyRounded(s.totalPurchases),
          icon: Icons.shopping_cart_outlined,
        ),
        ProfileStat(
          label: 'متوسط الأمر',
          value: Fmt.moneyRounded(s.averageOrder),
          icon: Icons.equalizer_rounded,
        ),
      ],
    );
  }
}
