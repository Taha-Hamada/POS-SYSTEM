import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/staggered_reveal.dart';
import '../../../core/widgets/stat_card.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/inventory_controller.dart';

/// صف البطاقات الإحصائية الأربعة فوق الجدول.
class InventoryStatCards extends StatefulWidget {
  const InventoryStatCards({super.key});

  @override
  State<InventoryStatCards> createState() => _InventoryStatCardsState();
}

class _InventoryStatCardsState extends State<InventoryStatCards>
    with SingleTickerProviderStateMixin {
  /// أنيميشن الدخول للبطاقات
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward();

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final InventoryController inventory =
        context.watch<InventoryController>();

    final List<Widget> cards = <Widget>[
      StatCard(
        title: 'إجمالي قيمة المخزون',
        value: Fmt.moneyRounded(inventory.totalValue),
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppColors.accent,
      ),
      StatCard(
        title: 'منتجات منخفضة المخزون',
        value: Fmt.count(inventory.lowCount),
        icon: Icons.trending_down_rounded,
        iconColor: AppColors.warning,
        higherIsBetter: false,
        changeLabel: 'مقارنة بالأسبوع الماضي',
      ),
      StatCard(
        title: 'منتجات نافدة',
        value: Fmt.count(inventory.outCount),
        icon: Icons.remove_shopping_cart_outlined,
        iconColor: AppColors.danger,
        higherIsBetter: false,
        changeLabel: 'مقارنة بالأسبوع الماضي',
      ),
      StatCard(
        title: 'قاربت على انتهاء الصلاحية',
        value: Fmt.count(inventory.nearExpiryCount),
        icon: Icons.event_busy_outlined,
        iconColor: AppColors.info,
        changeLabel: 'خلال الـ30 يوم القادمة',
        higherIsBetter: false,
      ),
    ];

    return Row(
      children: <Widget>[
        for (int i = 0; i < cards.length; i++) ...<Widget>[
          Expanded(
            child: StaggeredReveal(
              controller: _entryController,
              index: i,
              // نفس توقيت الأنيميشن الأصلي للبطاقات
              step: 0.12,
              span: 0.55,
              maxStart: 0.6,
              slideFrom: 0.18,
              child: cards[i],
            ),
          ),
          if (i != cards.length - 1) const SizedBox(width: AppSpacing.lg),
        ],
      ],
    );
  }
}
