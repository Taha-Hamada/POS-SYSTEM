import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/branch.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../controllers/inventory_controller.dart';

/// فلتر الفرع أو المخزن.
class InventoryBranchDropdown extends StatelessWidget {
  const InventoryBranchDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final InventoryController inventory = context.watch<InventoryController>();

    return AppDropdown<String?>(
      value: inventory.branchId,
      width: 240,
      icon: Icons.store_outlined,
      onChanged: inventory.setBranch,
      // مفيش «كل الفروع» لأن المخزون بيتحسب لفرع واحد على السيرفر.
      items: <AppDropdownItem<String?>>[
        for (final Branch b in inventory.branches)
          AppDropdownItem<String?>(
            value: b.id,
            label: b.name,
            icon: Icons.store_outlined,
          ),
      ],
    );
  }
}
