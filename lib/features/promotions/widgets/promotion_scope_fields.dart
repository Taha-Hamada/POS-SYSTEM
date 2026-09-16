import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../../core/models/promotion.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../theme/app_theme.dart';
import '../controllers/promotion_form_controller.dart';
import '../controllers/promotions_controller.dart';

/// العرض على إيه: كل المنتجات، قسم، أو منتجات مختارة.
class PromotionScopeFields extends StatelessWidget {
  const PromotionScopeFields({super.key});

  @override
  Widget build(BuildContext context) {
    final PromotionFormController form = context
        .watch<PromotionFormController>();
    final PromotionsController promotions = context
        .watch<PromotionsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LabeledField(
          label: 'العرض على',
          child: AppDropdown<PromotionScope>(
            value: form.scope,
            width: double.infinity,
            height: 48,
            icon: Icons.filter_alt_outlined,
            onChanged: form.setScope,
            items: <AppDropdownItem<PromotionScope>>[
              for (final PromotionScope s in PromotionScope.values)
                AppDropdownItem<PromotionScope>(value: s, label: s.label),
            ],
          ),
        ),
        if (form.scope == PromotionScope.category) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppDropdown<String?>(
            value: form.categoryId,
            width: double.infinity,
            height: 48,
            icon: Icons.category_outlined,
            hint: 'اختار القسم',
            onChanged: form.setCategory,
            items: <AppDropdownItem<String?>>[
              for (final Category c in promotions.categories)
                AppDropdownItem<String?>(value: c.id, label: c.name),
            ],
          ),
        ],
        if (form.scope == PromotionScope.products) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _ProductsPicker(form: form, catalog: promotions.catalog),
        ],
      ],
    );
  }
}

class _ProductsPicker extends StatelessWidget {
  const _ProductsPicker({required this.form, required this.catalog});

  final PromotionFormController form;
  final List<Product> catalog;

  @override
  Widget build(BuildContext context) {
    final String query = form.productQuery.trim().toLowerCase();

    // المختار بيظهر فوق عشان المدير يشوف اختياره من غير ما يدوّر.
    final List<Product> matches =
        catalog
            .where(
              (Product p) =>
                  query.isEmpty ||
                  p.name.toLowerCase().contains(query) ||
                  p.sku.toLowerCase().contains(query),
            )
            .toList()
          ..sort((Product a, Product b) {
            final int selected = (form.productIds.contains(b.id) ? 1 : 0)
                .compareTo(form.productIds.contains(a.id) ? 1 : 0);
            return selected != 0 ? selected : a.name.compareTo(b.name);
          });

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: TextField(
              onChanged: form.setProductQuery,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                hintText:
                    'دوّر باسم المنتج أو الكود — '
                    'مختار ${form.productIds.length}',
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: catalog.isEmpty
                ? Center(
                    child: Text('بنحمّل المنتجات…', style: AppText.caption),
                  )
                : ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (BuildContext context, int i) {
                      final Product p = matches[i];
                      return CheckboxListTile(
                        dense: true,
                        value: form.productIds.contains(p.id),
                        onChanged: (_) => form.toggleProduct(p.id),
                        title: Text(p.name, maxLines: 1),
                        subtitle: Text(p.sku, style: AppText.caption),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
