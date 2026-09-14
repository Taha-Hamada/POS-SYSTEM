import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/models/branch.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/stocktake_controller.dart';
import 'stocktake_count_chip.dart';

/// شريط الأدوات: فلتر الفرع، البحث، وعدّادات الجرد.
class StocktakeToolbar extends StatelessWidget {
  const StocktakeToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final StocktakeController stocktake = context.watch<StocktakeController>();

    return Row(
      children: <Widget>[
        AppDropdown<String>(
          value: stocktake.branchId,
          width: 260,
          icon: Icons.store_outlined,
          onChanged: stocktake.changeBranch,
          items: <AppDropdownItem<String>>[
            for (final Branch b in stocktake.branches)
              AppDropdownItem<String>(
                value: b.id,
                label: b.name,
                icon: Icons.store_outlined,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        SearchField(
          controller: stocktake.searchController,
          hint: 'ابحث عن صنف…',
          onChanged: stocktake.setQuery,
        ),
        const Spacer(),
        StocktakeCountChip(
          label: 'تم جردها',
          value: '${stocktake.countedCount} / ${stocktake.lines.length}',
          color: AppColors.accent,
          icon: Icons.checklist_rounded,
        ),
        const SizedBox(width: AppSpacing.sm),
        StocktakeCountChip(
          label: 'عجز',
          value: Fmt.count(stocktake.shortageCount),
          color: AppColors.danger,
          icon: Icons.trending_down_rounded,
        ),
        const SizedBox(width: AppSpacing.sm),
        StocktakeCountChip(
          label: 'زيادة',
          value: Fmt.count(stocktake.surplusCount),
          color: AppColors.success,
          icon: Icons.trending_up_rounded,
        ),
      ],
    );
  }
}
