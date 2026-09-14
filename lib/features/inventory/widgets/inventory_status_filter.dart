import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_dropdown.dart';
import '../../../utils/formatters.dart';
import '../controllers/inventory_controller.dart';

/// فلتر حالة الرصيد: الكل، ناقص، نافد، سليم.
///
/// الفلترة بتتعمل على السيرفر، فالعدّاد اللي جنب كل خيار هو العدد الحقيقي
/// في الفرع كله مش في الصفحة المعروضة.
class InventoryStatusFilter extends StatelessWidget {
  const InventoryStatusFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final InventoryController inventory = context.watch<InventoryController>();

    return AppDropdown<String?>(
      value: inventory.status,
      width: 200,
      icon: Icons.filter_alt_outlined,
      onChanged: inventory.setStatus,
      items: <AppDropdownItem<String?>>[
        AppDropdownItem<String?>(
          value: null,
          label: 'كل الأصناف',
          icon: Icons.apps_rounded,
          trailing: Fmt.count(inventory.summary.items),
        ),
        AppDropdownItem<String?>(
          value: 'low',
          label: 'تحت حد الطلب',
          icon: Icons.trending_down_rounded,
          trailing: Fmt.count(inventory.lowCount),
        ),
        AppDropdownItem<String?>(
          value: 'out',
          label: 'نافد',
          icon: Icons.remove_shopping_cart_outlined,
          trailing: Fmt.count(inventory.outCount),
        ),
        const AppDropdownItem<String?>(
          value: 'ok',
          label: 'رصيد سليم',
          icon: Icons.check_circle_outline_rounded,
        ),
      ],
    );
  }
}
