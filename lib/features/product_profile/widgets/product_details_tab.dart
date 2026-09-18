import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/models/category.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_form_field.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../add_edit_product/controllers/product_form_controller.dart';
import '../controllers/product_profile_controller.dart';
import 'product_profit_row.dart';
import 'product_save_bar.dart';

/// تبويب البيانات — نفس حقول المنتج بس قابلة للتعديل والحفظ من مكانها.
class ProductDetailsTab extends StatelessWidget {
  const ProductDetailsTab({super.key, required this.canEdit});

  /// من غير صلاحية `product:manage` الحقول بتتعرض للقراءة بس.
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final ProductProfileController p = context
        .watch<ProductProfileController>();

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: <Widget>[
        _card(
          icon: Icons.info_outline_rounded,
          title: 'بيانات أساسية',
          subtitle: 'الاسم والكود والقسم زي ما بيظهروا في البيع',
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: AppFormField(
                    label: 'اسم المنتج',
                    required: true,
                    enabled: canEdit,
                    controller: p.nameController,
                    onChanged: p.fieldChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: AppFormField(
                    label: 'كود المنتج (SKU)',
                    required: true,
                    enabled: canEdit,
                    controller: p.skuController,
                    onChanged: p.fieldChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: LabeledField(
                    label: 'القسم',
                    child: AppDropdown<String>(
                      height: 52,
                      icon: Icons.category_outlined,
                      hint: 'اختار القسم',
                      value: p.categoryId ?? '',
                      items: <AppDropdownItem<String>>[
                        for (final Category c in p.categories)
                          AppDropdownItem<String>(
                            value: c.id,
                            label: c.name,
                            icon: c.icon,
                          ),
                      ],
                      onChanged: canEdit ? p.setCategory : (_) {},
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: LabeledField(
                    label: 'الوحدة',
                    child: AppDropdown<String>(
                      height: 52,
                      icon: Icons.straighten_rounded,
                      hint: 'اختار الوحدة',
                      value: p.unit,
                      items: <AppDropdownItem<String>>[
                        for (final String u in _unitOptions(p.unit))
                          AppDropdownItem<String>(value: u, label: u),
                      ],
                      onChanged: canEdit ? p.setUnit : (_) {},
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: AppFormField(
                    label: 'الماركة',
                    enabled: canEdit,
                    controller: p.brandController,
                    onChanged: p.fieldChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppFormField(
              label: 'الوصف',
              maxLines: 3,
              enabled: canEdit,
              controller: p.descriptionController,
              onChanged: p.fieldChanged,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _card(
          icon: Icons.price_change_outlined,
          title: 'التسعير',
          subtitle: 'تعديل السعر من هنا بيتحفظ على السيرفر على طول',
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: AppFormField(
                    label: 'سعر البيع',
                    required: true,
                    enabled: canEdit,
                    controller: p.priceController,
                    suffixText: Fmt.currencySymbol,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _decimalOnly,
                    onChanged: p.fieldChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: AppFormField(
                    label: 'التكلفة',
                    required: true,
                    enabled: canEdit,
                    controller: p.costController,
                    suffixText: Fmt.currencySymbol,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _decimalOnly,
                    onChanged: p.fieldChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: AppFormField(
                    label: 'حد الطلب',
                    enabled: canEdit,
                    controller: p.minStockController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: p.fieldChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const ProductProfitRow(),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _card(
          icon: Icons.qr_code_2_rounded,
          title: 'الباركود',
          subtitle: 'سيبه فاضي لو المنتج مالوش باركود',
          children: <Widget>[
            AppFormField(
              label: 'الباركود',
              enabled: canEdit,
              controller: p.barcodeController,
              hint: 'مثال: 6221031234567',
              onChanged: p.fieldChanged,
            ),
          ],
        ),
        if (canEdit) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          const ProductSaveBar(),
        ],
      ],
    );
  }

  /// وحدة المنتج المحفوظة ممكن ماتكونش في القايمة الثابتة، فبتتضاف عشان
  /// ماتتغيرش لوحدها أول ما الشاشة تتفتح.
  static List<String> _unitOptions(String unit) =>
      unit.isEmpty || ProductFormController.units.contains(unit)
      ? ProductFormController.units
      : <String>[...ProductFormController.units, unit];

  static final List<TextInputFormatter> _decimalOnly = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.card(radius: AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FormSectionTitle(title: title, subtitle: subtitle, icon: icon),
          const SizedBox(height: AppSpacing.xl),
          ...children,
        ],
      ),
    );
  }
}
