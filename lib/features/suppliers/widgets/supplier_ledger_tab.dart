import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/purchase_order.dart';
import '../../../core/models/supplier.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/supplier_profile_controller.dart';
import 'supplier_ledger_chip.dart';

/// التبويب التاني: الحركات المالية مع المورد.
///
/// السيرفر مبيمسكش كشف حساب بسطوره للموردين — بيمسك المستحق الإجمالي
/// والقيمة المستلمة من كل أمر. فالحركات هنا هي القيم اللي اتحمّلت فعلًا على
/// الحساب من أوامر الشراء، والسداد بيظهر كإجمالي مش كسطور.
class SupplierLedgerTab extends StatelessWidget {
  const SupplierLedgerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final SupplierProfileController profile =
        context.watch<SupplierProfileController>();
    final Supplier? supplier = profile.supplier;

    if (supplier == null) return const SizedBox.shrink();

    // الأوامر اللي دخل منها بضاعة فعلًا هي اللي اتحمّلت على الحساب.
    final List<PurchaseOrder> charges = profile.orders
        .where((PurchaseOrder o) => o.receivedValue > 0)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // الشارات بتلف لسطر تاني بدل ما تطلع بره الشاشة على العرض الضيق.
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            SupplierLedgerChip(
              label: 'إجمالي المستلم على الحساب',
              value: Fmt.money(supplier.totalPurchases),
              color: AppColors.info,
            ),
            SupplierLedgerChip(
              label: 'إجمالي المدفوع',
              value: Fmt.money(supplier.paidAmount),
              color: AppColors.success,
            ),
            SupplierLedgerChip(
              label: 'المستحق للمورد',
              value: Fmt.money(supplier.balanceDue),
              color: supplier.hasDue ? AppColors.danger : AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: AppDataTable(
            title: 'الحركات على الحساب',
            subtitle:
                '${Fmt.count(charges.length)} أمر دخلت منه بضاعة على الحساب',
            minWidth: 820,
            rowHeight: 60,
            emptyMessage: 'مفيش حركات على حساب المورد لسه',
            emptyIcon: Icons.account_balance_outlined,
            columns: const <AppTableColumn>[
              AppTableColumn('رقم الأمر', size: ColumnSize.S),
              AppTableColumn('التاريخ', size: ColumnSize.M),
              AppTableColumn('الحالة', size: ColumnSize.M),
              AppTableColumn(
                'قيمة الأمر',
                size: ColumnSize.M,
                numeric: true,
              ),
              AppTableColumn(
                'المُحمّل على الحساب',
                size: ColumnSize.M,
                numeric: true,
                tooltip: 'قيمة البضاعة اللي اتستلمت فعلًا',
              ),
            ],
            rows: <AppTableRow>[
              for (final PurchaseOrder o in charges)
                AppTableRow(
                  cells: <Widget>[
                    Text(
                      o.number,
                      style: AppText.amountSm.copyWith(fontSize: 13),
                    ),
                    TableCells.secondary(Fmt.date(o.orderDate)),
                    StatusBadge(label: o.status.label, tone: o.status.tone),
                    TableCells.amount(o.total),
                    Text(
                      Fmt.money(o.receivedValue),
                      style: AppText.amountSm.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
