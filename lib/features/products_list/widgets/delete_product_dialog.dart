import 'package:flutter/material.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/models/product.dart';
import '../../../theme/app_theme.dart';

/// بيطلب تأكيد إيقاف منتج — بيرجّع true لو المستخدم أكّد.
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
      title: const Text('إيقاف المنتج'),
      content: Text(
        '«${product.name}» هيختفي من شاشة البيع، وفواتيره القديمة ورصيده '
        'هيفضلوا زي ما هم. تقدر ترجّعه بعدين من تبويب «غير نشطة».',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        PrimaryButton(
          label: 'إيقاف',
          color: AppColors.danger,
          size: AppButtonSize.small,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
