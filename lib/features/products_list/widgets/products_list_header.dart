import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/products_list_controller.dart';
import '../models/products_filter.dart';
import 'products_category_dropdown.dart';
import 'products_search_field.dart';

/// الشريط العلوي: العنوان والعدّاد، البحث، الفئة، وزرار الإضافة.
class ProductsListHeader extends StatelessWidget {
  const ProductsListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final int visibleCount =
        context.select((ProductsListController p) => p.visibleCount);

    final int totalCount =
        context.select((ProductsListController p) => p.countFor(ProductsFilter.all));

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('المنتجات', style: AppText.pageTitle.copyWith(fontSize: 24)),
              const SizedBox(height: 3),
              Text(
                'عرض ${Fmt.count(visibleCount)} من إجمالي '
                '${Fmt.count(totalCount)} منتج',
                style: AppText.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        const ProductsSearchField(),
        const SizedBox(width: AppSpacing.md),
        const ProductsCategoryDropdown(),
        const SizedBox(width: AppSpacing.md),
        PrimaryButton(
          label: 'إضافة منتج',
          icon: Icons.add_rounded,
          onPressed: () => context.go('/products/new'),
        ),
      ],
    );
  }
}
