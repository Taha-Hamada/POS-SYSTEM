import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/promotion.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../controllers/promotions_controller.dart';

/// فلتر نوع العرض.
class PromotionsTypeDropdown extends StatelessWidget {
  const PromotionsTypeDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final PromotionsController promotions = context
        .watch<PromotionsController>();

    return AppDropdown<PromotionType?>(
      value: promotions.typeFilter,
      width: 200,
      icon: Icons.sell_outlined,
      onChanged: promotions.setTypeFilter,
      items: <AppDropdownItem<PromotionType?>>[
        const AppDropdownItem<PromotionType?>(
          value: null,
          label: 'كل الأنواع',
          icon: Icons.apps_rounded,
        ),
        for (final PromotionType t in PromotionType.values)
          AppDropdownItem<PromotionType?>(
            value: t,
            label: t.label,
            icon: t.icon,
          ),
      ],
    );
  }
}
