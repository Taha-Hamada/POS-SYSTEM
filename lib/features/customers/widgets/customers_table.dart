import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/hover_row_button.dart';
import '../../../core/widgets/phone_cell.dart';
import '../../../core/models/customer.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/customers_list_controller.dart';
import 'customer_balance_cell.dart';
import 'customers_table_footer.dart';

/// جدول العملاء.
class CustomersTable extends StatelessWidget {
  const CustomersTable({super.key});

  static const List<AppTableColumn> _columns = <AppTableColumn>[
    AppTableColumn('العميل', size: ColumnSize.L, sortable: true),
    AppTableColumn('الهاتف', size: ColumnSize.M, sortable: true),
    AppTableColumn(
      'الرصيد',
      size: ColumnSize.M,
      sortable: true,
      numeric: true,
      tooltip: 'أحمر = مدين علينا نحصّله، أخضر = دائن له عندنا',
    ),
    AppTableColumn('آخر عملية شراء', size: ColumnSize.M, sortable: true),
    AppTableColumn('', fixedWidth: 110),
  ];

  List<Widget> _cells(BuildContext context, Customer c, bool hovered) {
    return <Widget>[
      TableCells.avatarName(
        c.name,
        c.initials,
        color: AppColors.accent,
        subtitle: c.email ?? c.phone,
      ),
      PhoneCell(phone: c.phone),
      CustomerBalanceCell(balance: c.balance),
      TableCells.twoLine(
        c.lastVisitAt == null ? 'مجاش لسه' : Fmt.date(c.lastVisitAt!),
        '${Fmt.count(c.ordersCount)} فاتورة',
      ),
      HoverRowButton(
        label: 'الملف',
        hovered: hovered,
        onPressed: () => context.go('/customers/${c.id}'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final CustomersListController customers =
        context.watch<CustomersListController>();

    return AppDataTable(
      minWidth: 1020,
      rowHeight: 66,
      sortColumnIndex: customers.sortIndex,
      sortAscending: customers.sortAscending,
      onSort: customers.sortBy,
      emptyMessage: 'لا يوجد عملاء مطابقون للبحث',
      emptyIcon: Icons.people_outline_rounded,
      columns: _columns,
      rows: <AppTableRow>[
        for (final Customer c in customers.rows)
          AppTableRow(
            onTap: () => context.go('/customers/${c.id}'),
            cellsBuilder: (bool hovered) => _cells(context, c, hovered),
          ),
      ],
      footer: const CustomersTableFooter(),
    );
  }
}
