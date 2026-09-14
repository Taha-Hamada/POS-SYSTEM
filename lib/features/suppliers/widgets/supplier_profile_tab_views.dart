import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/supplier_profile_controller.dart';
import 'supplier_ledger_tab.dart';
import 'supplier_orders_tab.dart';
import 'supplier_products_tab.dart';

/// محتوى تبويبات ملف المورد — الترتيب لازم يطابق [SupplierProfileTab].
class SupplierProfileTabViews extends StatelessWidget {
  const SupplierProfileTabViews({super.key});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: context.read<SupplierProfileController>().tabController,
      children: const <Widget>[
        SupplierProductsTab(),
        SupplierLedgerTab(),
        SupplierOrdersTab(),
      ],
    );
  }
}
