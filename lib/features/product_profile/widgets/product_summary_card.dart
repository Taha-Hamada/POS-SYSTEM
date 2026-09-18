import 'package:flutter/material.dart';

import '../../../core/models/product.dart';
import '../../../core/widgets/profile_summary_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// بطاقة ملخّص المنتج أعلى شاشة التفاصيل.
class ProductSummaryCard extends StatelessWidget {
  const ProductSummaryCard({
    super.key,
    required this.product,
    required this.onHand,
    required this.branches,
  });

  final Product product;

  /// الإجماليات محسوبة على كل الفروع مش على فرع المستخدم.
  final double onHand;
  final int branches;

  @override
  Widget build(BuildContext context) {
    final Product p = product;

    return ProfileSummaryCard(
      name: p.name,
      avatarColor: p.accentColor,
      avatarIcon: p.categoryIcon,
      subtitle:
          '${p.categoryName} • ${Fmt.count(branches)} فرع • '
          'هامش ${Fmt.percent(p.profitMargin)}',
      badge: p.isActive
          ? StatusBadge.stock(stock: onHand, minStock: p.minStock)
          : const StatusBadge(label: 'غير نشط', tone: StatusTone.neutral),
      meta: <(IconData, String)>[
        (Icons.tag_rounded, 'SKU ${p.sku}'),
        (
          Icons.qr_code_scanner_rounded,
          (p.barcode?.isNotEmpty ?? false) ? p.barcode! : 'من غير باركود',
        ),
        (Icons.sell_outlined, p.brand.isEmpty ? 'من غير ماركة' : p.brand),
      ],
      stats: <ProfileStat>[
        ProfileStat(
          label: 'سعر البيع',
          value: Fmt.money(p.price),
          icon: Icons.payments_outlined,
          big: true,
        ),
        ProfileStat(
          label: 'التكلفة',
          value: Fmt.money(p.cost),
          icon: Icons.shopping_cart_outlined,
        ),
        ProfileStat(
          label: 'الرصيد',
          value: '${Fmt.qty(onHand)} ${p.unit}'.trim(),
          icon: Icons.inventory_2_outlined,
          color: onHand <= 0
              ? AppColors.danger
              : onHand <= p.minStock
              ? AppColors.warning
              : AppColors.success,
        ),
      ],
    );
  }
}
