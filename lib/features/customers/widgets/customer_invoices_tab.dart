import 'package:flutter/material.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/status_badge.dart';
import 'package:provider/provider.dart';

import '../../../core/models/customer.dart';
import '../controllers/customer_profile_controller.dart';
import '../models/customer_entries.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import 'invoice_payment_method_cell.dart';

/// التبويب الأول: سجل مشتريات العميل.
class CustomerInvoicesTab extends StatelessWidget {
  const CustomerInvoicesTab({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final List<CustomerInvoice> invoices =
        context.watch<CustomerProfileController>().invoices;

    return AppDataTable(
      title: 'فواتير العميل',
      subtitle: '${Fmt.count(invoices.length)} فاتورة مسجّلة',
      minWidth: 900,
      rowHeight: 58,
      emptyMessage: 'لا توجد فواتير لهذا العميل',
      emptyIcon: Icons.receipt_long_outlined,
      columns: const <AppTableColumn>[
        AppTableColumn('رقم الفاتورة', size: ColumnSize.M),
        AppTableColumn('التاريخ', size: ColumnSize.M),
        AppTableColumn('عدد الأصناف', size: ColumnSize.S, numeric: true),
        AppTableColumn('طريقة الدفع', size: ColumnSize.M),
        AppTableColumn('الحالة', size: ColumnSize.S),
        AppTableColumn('الإجمالي', size: ColumnSize.M, numeric: true),
      ],
      rows: <AppTableRow>[
        for (final CustomerInvoice inv in invoices)
          AppTableRow(
            cells: <Widget>[
              Text(inv.number, style: AppText.amountSm.copyWith(fontSize: 13)),
              Text(
                Fmt.date(inv.createdAt),
                style: AppText.body.copyWith(fontSize: 13),
              ),
              TableCells.count(inv.itemsCount),
              InvoicePaymentMethodCell(method: inv.primaryMethod),
              StatusBadge(
                label: inv.isVoided
                    ? 'ملغاة'
                    : inv.hasReturns
                        ? 'عليها مرتجع'
                        : 'مكتملة',
                tone: inv.isVoided
                    ? StatusTone.danger
                    : inv.hasReturns
                        ? StatusTone.warning
                        : StatusTone.success,
                compact: true,
              ),
              TableCells.amount(inv.total),
            ],
          ),
      ],
      footer: Row(
        children: <Widget>[
          Text('إجمالي المشتريات', style: AppText.caption),
          const Spacer(),
          Text(
            Fmt.money(
              invoices.fold<double>(
                0,
                (double s, CustomerInvoice i) => s + i.total,
              ),
            ),
            style: AppText.amountMd,
          ),
        ],
      ),
    );
  }
}
