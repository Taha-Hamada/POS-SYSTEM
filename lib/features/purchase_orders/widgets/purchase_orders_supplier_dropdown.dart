import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/supplier.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../controllers/purchase_orders_controller.dart';

/// فلتر المورد فوق جدول الأوامر.
class PurchaseOrdersSupplierDropdown extends StatelessWidget {
  const PurchaseOrdersSupplierDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final PurchaseOrdersController orders =
        context.watch<PurchaseOrdersController>();

    return AppDropdown<String?>(
      value: orders.supplierId,
      width: 220,
      icon: Icons.local_shipping_outlined,
      onChanged: orders.setSupplier,
      items: <AppDropdownItem<String?>>[
        const AppDropdownItem<String?>(
          value: null,
          label: 'كل الموردين',
          icon: Icons.apps_rounded,
        ),
        for (final Supplier s in orders.suppliers)
          AppDropdownItem<String?>(
            value: s.id,
            label: s.name,
            icon: Icons.storefront_outlined,
          ),
      ],
    );
  }
}
