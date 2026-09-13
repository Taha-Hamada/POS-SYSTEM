import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/models/product.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/products_list_controller.dart';
import 'product_category_cell.dart';
import 'product_name_cell.dart';
import 'product_row_actions.dart';
import 'product_stock_cell.dart';
import 'products_table_footer.dart';

/// جدول المنتجات بأعمدته وصفوفه.
class ProductsTable extends StatelessWidget {
  const ProductsTable({super.key});

  static const List<AppTableColumn> _columns = <AppTableColumn>[
    AppTableColumn('المنتج', size: ColumnSize.L, sortable: true),
    AppTableColumn('SKU', size: ColumnSize.S, sortable: true),
    AppTableColumn('الفئة', size: ColumnSize.M, sortable: true),
    AppTableColumn(
      'سعر البيع',
      size: ColumnSize.S,
      sortable: true,
      numeric: true,
    ),
    AppTableColumn('الكمية', size: ColumnSize.S, sortable: true, numeric: true),
    AppTableColumn('الحالة', size: ColumnSize.M, sortable: true),
    AppTableColumn('إجراءات', fixedWidth: 110),
  ];

  List<Widget> _cells(Product p, bool hovered) {
    return <Widget>[
      ProductNameCell(product: p),
      Text(
        p.sku,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      ProductCategoryCell(product: p),
      Text(Fmt.money(p.price), style: AppText.amountSm),
      ProductStockCell(product: p),
      p.isActive
          ? StatusBadge.stock(stock: p.stock, minStock: p.minStock)
          : const StatusBadge(label: 'غير نشط', tone: StatusTone.neutral),
      ProductRowActions(product: p, hovered: hovered),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ProductsListController products =
        context.watch<ProductsListController>();

    return AppDataTable(
      minWidth: 1080,
      rowHeight: 66,
      sortColumnIndex: products.sortIndex,
      sortAscending: products.sortAscending,
      onSort: products.sortBy,
      emptyMessage: 'لا توجد منتجات مطابقة للفلتر الحالي',
      emptyIcon: Icons.inventory_2_outlined,
      columns: _columns,
      rows: <AppTableRow>[
        for (final Product p in products.rows)
          AppTableRow(
            cellsBuilder: (bool hovered) => _cells(p, hovered),
            onTap: () =>
                showPlainSnackBar(context, 'فتح تفاصيل «${p.name}»'),
          ),
      ],
      footer: const ProductsTableFooter(),
    );
  }
}
