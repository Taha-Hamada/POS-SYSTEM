import 'package:flutter/material.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/models/product.dart';
import '../../../theme/app_theme.dart';

/// بيطلب تأكيد حذف منتج — بيرجّع true لو المستخدم أكّد.
Future<bool?> showDeleteProductDialog(BuildContext context, Product product) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) => DeleteProductDialog(product: product),
  );
}

class DeleteProductDialog extends StatelessWidget {
  const DeleteProductDialog({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تأكيد الحذف'),
      content: Text(
        'هل أنت متأكد من حذف «${product.name}»؟ '
        'لا يمكن التراجع عن هذا الإجراء.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        PrimaryButton(
          label: 'حذف',
          color: AppColors.danger,
          size: AppButtonSize.small,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
