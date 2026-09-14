import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/supplier.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/hover_row_button.dart';
import '../../../core/widgets/phone_cell.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../controllers/suppliers_list_controller.dart';
import 'supplier_due_cell.dart';
import 'supplier_name_cell.dart';
import 'suppliers_table_footer.dart';

/// جدول الموردين.
class SuppliersTable extends StatelessWidget {
  const SuppliersTable({super.key});

  static const List<AppTableColumn> _columns = <AppTableColumn>[
    AppTableColumn('المورد', size: ColumnSize.L, sortable: true),
    AppTableColumn('مسؤول التواصل', size: ColumnSize.M, sortable: true),
    AppTableColumn('الهاتف', size: ColumnSize.M, sortable: true),
    AppTableColumn(
      'الرصيد المستحق',
      size: ColumnSize.M,
      sortable: true,
      numeric: true,
      tooltip: 'المبالغ الواجب سدادها للمورد',
    ),
    AppTableColumn('أوامر التوريد', size: ColumnSize.S, sortable: true),
    AppTableColumn('الحالة', size: ColumnSize.S),
    AppTableColumn('', fixedWidth: 110),
  ];

  List<Widget> _cells(BuildContext context, Supplier s, bool hovered) {
    return <Widget>[
      SupplierNameCell(supplier: s),
      Text(
        s.contactPerson.isEmpty ? '—' : s.contactPerson,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.body.copyWith(fontSize: 13),
      ),
      PhoneCell(phone: s.phone),
      SupplierDueCell(balanceDue: s.balanceDue),
      TableCells.count(s.ordersCount),
      StatusBadge(
        label: s.isActive ? 'نشط' : 'موقوف',
        tone: s.isActive ? StatusTone.success : StatusTone.neutral,
      ),
      HoverRowButton(
        label: 'الملف',
        hovered: hovered,
        onPressed: () => context.go('/suppliers/${s.id}'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final SuppliersListController suppliers =
        context.watch<SuppliersListController>();

    if (suppliers.isFirstLoad) {
      return const LoadingView(message: 'بنجيب الموردين…');
    }

    if (suppliers.hasFailed) {
      return ErrorView(
        message: suppliers.errorMessage!,
        onRetry: suppliers.retry,
      );
    }

    return AppDataTable(
      minWidth: 1060,
      rowHeight: 66,
      sortColumnIndex: suppliers.sortIndex,
      sortAscending: suppliers.sortAscending,
      onSort: suppliers.sortBy,
      emptyMessage: 'لا يوجد موردون مطابقون للبحث',
      emptyIcon: Icons.local_shipping_outlined,
      columns: _columns,
      rows: <AppTableRow>[
        for (final Supplier s in suppliers.rows)
          AppTableRow(
            onTap: () => context.go('/suppliers/${s.id}'),
            cellsBuilder: (bool hovered) => _cells(context, s, hovered),
          ),
      ],
      footer: const SuppliersTableFooter(),
    );
  }
}
