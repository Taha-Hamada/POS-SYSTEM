import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_form_field.dart';
import '../../../core/models/category.dart';
import '../../../theme/app_theme.dart';
import '../controllers/product_form_controller.dart';
import 'labeled_dropdown.dart';
import 'product_form_tab_card.dart';
import 'product_image_drop_zone.dart';

/// التبويب الأول: اسم المنتج وتصنيفه ووصفه وصوره.
class BasicInfoTab extends StatelessWidget {
  const BasicInfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductFormController form = context.watch<ProductFormController>();

    return ProductFormTabCard(
      children: <Widget>[
        const FormSectionTitle(
          title: 'البيانات الأساسية',
          subtitle: 'اسم المنتج وتصنيفه ووصفه المختصر',
          icon: Icons.description_outlined,
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: AppFormField(
                label: 'اسم المنتج',
                controller: form.nameController,
                hint: 'مثال: أرز مصري فاخر 1 كجم',
                required: true,
                onChanged: form.fieldChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppFormField(
                label: 'كود المنتج (SKU)',
                controller: form.skuController,
                hint: 'مثال: RICE-1KG',
                required: true,
                onChanged: form.fieldChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: LabeledDropdown<String?>(
                label: 'الفئة',
                value: form.categoryId,
                onChanged: (String? id) {
                  if (id != null) form.setCategory(id);
                },
                items: <AppDropdownItem<String?>>[
                  for (final Category c in form.categories)
                    AppDropdownItem<String?>(
                      value: c.id,
                      label: c.name,
                      icon: c.icon,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: AppFormField(
                label: 'الماركة',
                controller: form.brandController,
                hint: 'اختياري',
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            const Spacer(flex: 2),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppFormField(
          label: 'الوصف',
          controller: form.descriptionController,
          hint: 'وصف مختصر يظهر في الفاتورة وشاشة المنتجات…',
          maxLines: 4,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('صور المنتج', style: AppText.label.copyWith(fontSize: 12.5)),
        const SizedBox(height: AppSpacing.md),
        const ProductImageDropZone(),
      ],
    );
  }
}
