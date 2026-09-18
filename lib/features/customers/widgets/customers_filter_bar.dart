import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/customers_list_controller.dart';
import 'customers_toggle_chip.dart';

/// شريط فوق الجدول: العنوان والعدّاد وفلاتر المدينين والبحث والمجموعة.
class CustomersFilterBar extends StatelessWidget {
  const CustomersFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomersListController customers =
        context.watch<CustomersListController>();

    return Row(
      children: <Widget>[
        Text('قائمة العملاء', style: AppText.sectionTitle),
        const SizedBox(width: AppSpacing.md),
        Text('(${Fmt.count(customers.visibleCount)})', style: AppText.caption),
        const Spacer(),
        CustomersToggleChip(
          label: 'المدينون فقط',
          icon: Icons.error_outline_rounded,
          selected: customers.onlyDebtors,
          onTap: customers.toggleOnlyDebtors,
        ),
        const SizedBox(width: AppSpacing.md),
        SearchField(
          controller: customers.searchController,
          hint: 'ابحث بالاسم أو الهاتف…',
          onChanged: customers.setQuery,
        ),
      ],
    );
  }
}
