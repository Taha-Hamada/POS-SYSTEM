import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../../theme/app_theme.dart';
import '../controllers/sales_session_controller.dart';
import 'product_category_tab_label.dart';

/// شريط تبويبات فئات المنتجات.
class ProductCategoryTabs extends StatelessWidget {
  const ProductCategoryTabs({super.key, required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final SalesSessionController session =
        context.watch<SalesSessionController>();

    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: AppDecorations.card(radius: AppRadius.md),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 3),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        tabs: <Widget>[
          Tab(
            height: 42,
            child: ProductCategoryTabLabel(
              icon: Icons.apps_rounded,
              label: 'الكل',
              count: session.products.length,
            ),
          ),
          for (final Category c in session.categories)
            Tab(
              height: 42,
              child: ProductCategoryTabLabel(
                icon: c.icon,
                label: c.name,
                count: session.products
                    .where((Product p) => p.categoryId == c.id)
                    .length,
              ),
            ),
        ],
      ),
    );
  }
}
