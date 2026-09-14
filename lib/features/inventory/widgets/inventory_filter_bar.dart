import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/inventory_controller.dart';
import 'inventory_branch_dropdown.dart';
import 'inventory_status_filter.dart';

/// شريط فوق الجدول: عنوان القسم، عدد السجلات، وفلتر الفرع.
class InventoryFilterBar extends StatelessWidget {
  const InventoryFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final int count =
        context.select((InventoryController i) => i.visibleCount);

    return Row(
      children: <Widget>[
        Text('أرصدة المخزون', style: AppText.sectionTitle),
        const SizedBox(width: AppSpacing.md),
        Text('(${Fmt.count(count)} سجل)', style: AppText.caption),
        const Spacer(),
        const InventoryStatusFilter(),
        const SizedBox(width: AppSpacing.md),
        const InventoryBranchDropdown(),
      ],
    );
  }
}
