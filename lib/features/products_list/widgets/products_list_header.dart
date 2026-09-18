import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/session/session_controller.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/products_list_controller.dart';
import '../models/products_filter.dart';
import 'products_category_dropdown.dart';
import 'products_search_field.dart';

/// بيفتح شاشة فوق قايمة المنتجات وبيعيد تحميل القايمة لما ترجع.
///
/// الفورم والأقسام بيتفتحوا فوق القايمة من غير ما تتقفل، فمن غير إعادة
/// التحميل المنتج الجديد مكانش بيبان في البحث لحد ما الشاشة تتفتح من جديد.
Future<void> openOverProducts(BuildContext context, String location) async {
  final ProductsListController products = context
      .read<ProductsListController>();

  await context.push<bool>(location);
  if (!context.mounted) return;

  await products.load();
}

/// الشريط العلوي: العنوان والعدّاد، البحث، الفئة، والأزرار.
class ProductsListHeader extends StatelessWidget {
  const ProductsListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final int visibleCount = context.select(
      (ProductsListController p) => p.visibleCount,
    );

    final int totalCount = context.select(
      (ProductsListController p) => p.countFor(ProductsFilter.all),
    );

    final SessionController session = context.read<SessionController>();

    // سطرين: العنوان والأزرار فوق، والبحث والفلتر تحت — في سطر واحد
    // الأزرار الجديدة كانت بتخرج برّه الشاشة على عرض 1440.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'المنتجات',
                    style: AppText.pageTitle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'عرض ${Fmt.count(visibleCount)} من إجمالي '
                    '${Fmt.count(totalCount)} منتج',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            SecondaryButton(
              label: 'الأقسام',
              icon: Icons.category_outlined,
              onPressed: () =>
                  openOverProducts(context, '/products/categories'),
            ),
            if (session.can('product:manage')) ...<Widget>[
              const SizedBox(width: AppSpacing.md),
              PrimaryButton(
                label: 'إضافة منتج',
                icon: Icons.add_rounded,
                onPressed: () => openOverProducts(context, '/products/new'),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const Row(
          children: <Widget>[
            ProductsSearchField(),
            SizedBox(width: AppSpacing.md),
            ProductsCategoryDropdown(),
          ],
        ),
      ],
    );
  }
}
