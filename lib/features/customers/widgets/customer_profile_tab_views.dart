import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/customer.dart';
import '../controllers/customer_profile_controller.dart';
import 'customer_invoices_tab.dart';
import 'customer_ledger_tab.dart';
import 'customer_loyalty_tab.dart';

/// محتوى تبويبات ملف العميل — الترتيب لازم يطابق [CustomerProfileTab].
class CustomerProfileTabViews extends StatelessWidget {
  const CustomerProfileTabViews({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: context.read<CustomerProfileController>().tabController,
      children: <Widget>[
        CustomerInvoicesTab(customer: customer),
        CustomerLedgerTab(customer: customer),
        CustomerLoyaltyTab(customer: customer),
      ],
    );
  }
}
