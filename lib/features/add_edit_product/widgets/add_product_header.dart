import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/product_form_controller.dart';
import 'add_product_back_button.dart';
import 'add_product_footer.dart';

/// هيدر الشاشة: زرار الرجوع + العنوان والوصف.
class AddProductHeader extends StatelessWidget {
  const AddProductHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final bool editing = context.read<ProductFormController>().isEditing;

    return Row(
      children: <Widget>[
        AddProductBackButton(onTap: () => closeProductForm(context)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                editing ? 'تعديل منتج' : 'إضافة منتج جديد',
                style: AppText.pageTitle.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 3),
              Text(
                editing
                    ? 'عدّل البيانات ثم اضغط «حفظ التعديلات» — الرصيد بيتغير من شاشة المخزون'
                    : 'املأ البيانات في التبويبات التالية ثم اضغط «حفظ المنتج»',
                style: AppText.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
