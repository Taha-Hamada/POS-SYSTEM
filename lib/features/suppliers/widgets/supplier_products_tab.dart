import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/supplier_profile_controller.dart';
import '../models/supplied_product.dart';
import 'supplier_product_cell.dart';

/// التبويب الأول: الأصناف اللي المورد وردها فعلًا.
///
/// المنتج مش مربوط بمورد على السيرفر، فالقايمة دي محسوبة من أوامر الشراء:
/// اللي اتطلب منه فعلًا، بآخر سعر اتدفع فيه.
class SupplierProductsTab extends StatelessWidget {
  const SupplierProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final SupplierProfileController profile =
        context.watch<SupplierProfileController>();
    final List<SuppliedProduct> products = profile.products;

    return AppDataTable(
      title: 'الأصناف الموردة',
      subtitle: '${Fmt.count(products.length)} صنف اتطلب من المورد ده',
      minWidth: 980,
      rowHeight: 60,
      emptyMessage: 'مفيش أصناف اتطلبت من المورد ده لسه',
      emptyIcon: Icons.inventory_2_outlined,
      columns: const <AppTableColumn>[
        AppTableColumn('الصنف', size: ColumnSize.L),
        AppTableColumn('SKU', size: ColumnSize.S),
        AppTableColumn('الفئة', size: ColumnSize.M),
        AppTableColumn(
          'آخر سعر شراء',
          size: ColumnSize.S,
          numeric: true,
          tooltip: 'آخر سعر اتدفع للمورد ده في الصنف',
        ),
        AppTableColumn('سعر البيع', size: ColumnSize.S, numeric: true),
        AppTableColumn(
          'المستلم / المطلوب',
          size: ColumnSize.M,
          numeric: true,
          tooltip: 'إجمالي الكميات على كل أوامر المورد',
        ),
        AppTableColumn('المخزون', size: ColumnSize.S, numeric: true),
      ],
      rows: <AppTableRow>[
        for (final SuppliedProduct p in products)
          AppTableRow(
            cells: <Widget>[
              SupplierProductCell(product: p),
              TableCells.secondary(p.sku),
              TableCells.secondary(p.categoryName),
              // سعر الشراء بلون مميّز لأنه العمود المهم هنا
              Text(
                Fmt.money(p.lastUnitCost),
                style: AppText.amountSm.copyWith(color: AppColors.accent),
              ),
              TableCells.amount(p.price),
              Text(
                '${Fmt.count(p.receivedQuantity.round())} / '
                '${Fmt.count(p.orderedQuantity.round())}',
                style: AppText.amountSm.copyWith(
                  color: p.receivedQuantity < p.orderedQuantity
                      ? AppColors.warning
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '${Fmt.count(p.stock)} ${p.unit}',
                style: AppText.amountSm.copyWith(
                  color: p.isLowStock || p.isOutOfStock
                      ? AppColors.danger
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
      ],
      footer: Row(
        children: <Widget>[
          Text('متوسط هامش الربح بآخر أسعار المورد', style: AppText.caption),
          const Spacer(),
          Text(
            products.isEmpty ? '—' : Fmt.percent(profile.averageMargin),
            style: AppText.amountMd.copyWith(
              color: profile.averageMargin >= 0
                  ? AppColors.success
                  : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
