import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_dropdown.dart';

import '../../../utils/formatters.dart';
import '../controllers/customers_list_controller.dart';
import '../models/customer_tier_tone.dart';

/// فلتر مجموعة العميل.
class CustomersTierDropdown extends StatelessWidget {
  const CustomersTierDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomersListController customers =
        context.watch<CustomersListController>();

    return AppDropdown<String?>(
      value: customers.tier,
      width: 190,
      icon: Icons.workspace_premium_outlined,
      onChanged: customers.setTier,
      items: <AppDropdownItem<String?>>[
        AppDropdownItem<String?>(
          value: null,
          label: 'كل المجموعات',
          icon: Icons.apps_rounded,
          trailing: Fmt.count(customers.allCustomers.length),
        ),
        for (final String t in kCustomerTiers)
          AppDropdownItem<String?>(
            value: t,
            label: t.tierLabel,
            trailing: Fmt.count(customers.tierCount(t)),
          ),
      ],
    );
  }
}
