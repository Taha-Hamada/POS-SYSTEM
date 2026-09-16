import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/promotion.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/promotions_controller.dart';
import '../models/promotion_status_tone.dart';
import 'promotion_status_pill.dart';
import 'promotions_type_dropdown.dart';

/// شريط الفلترة: شرائح الحالة + فلتر النوع.
class PromotionsFilterBar extends StatelessWidget {
  const PromotionsFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final PromotionsController promotions = context
        .watch<PromotionsController>();

    return Row(
      children: <Widget>[
        Text('كل العروض', style: AppText.sectionTitle),
        const SizedBox(width: AppSpacing.md),
        Text('(${Fmt.count(promotions.visibleCount)})', style: AppText.caption),
        const SizedBox(width: AppSpacing.xl),
        for (final PromotionStatus s in PromotionStatus.values) ...<Widget>[
          PromotionStatusPill(
            label: s.label,
            count: promotions.countByStatus(s),
            color: s.pillColor,
            selected: promotions.statusFilter == s,
            onTap: () => promotions.toggleStatusFilter(s),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        const Spacer(),
        const PromotionsTypeDropdown(),
      ],
    );
  }
}
