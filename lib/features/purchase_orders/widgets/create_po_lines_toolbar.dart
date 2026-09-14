import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/product.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/product_picker_dialog.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/create_purchase_order_controller.dart';

/// يفتح نافذة اختيار منتج ويضيفه للأمر.
Future<void> pickProductForOrder(BuildContext context) async {
  final CreatePurchaseOrderController draft =
      context.read<CreatePurchaseOrderController>();

  final Product? product = await showProductPicker(
    context,
    catalog: draft.catalog,
    excludedIds: draft.pickedProductIds,
  );

  if (product == null) return;

  draft.addProduct(product);
}

/// شريط عنوان جدول الأصناف مع أزرار الإضافة.
class CreatePoLinesToolbar extends StatelessWidget {
  const CreatePoLinesToolbar({super.key});

  /// بيضيف الأصناف اللي المورد ده وردها قبل كده، بآخر سعر اتدفع فيه.
  Future<void> _addCatalog(BuildContext context) async {
    final CreatePurchaseOrderController draft =
        context.read<CreatePurchaseOrderController>();

    final ({int added, String? error}) result = await draft.addSupplierCatalog();
    if (!context.mounted) return;

    if (result.error != null) {
      showPlainSnackBar(context, result.error!);
      return;
    }

    if (result.added == 0) {
      showPlainSnackBar(
        context,
        'مفيش أصناف جديدة اتطلبت من المورد ده قبل كده',
        width: 460,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final CreatePurchaseOrderController draft =
        context.watch<CreatePurchaseOrderController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Text('أصناف الأمر', style: AppText.sectionTitle),
          const SizedBox(width: AppSpacing.sm),
          if (draft.hasLines)
            Text(
              '(${Fmt.count(draft.lines.length)} صنف • '
              '${Fmt.count(draft.totalUnits)} وحدة)',
              style: AppText.caption,
            ),
          const Spacer(),
          SecondaryButton(
            label: 'إضافة كتالوج المورد',
            icon: Icons.library_add_outlined,
            size: AppButtonSize.small,
            onPressed: () => _addCatalog(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          PrimaryButton(
            label: 'إضافة صنف',
            icon: Icons.add_rounded,
            size: AppButtonSize.small,
            onPressed: () => pickProductForOrder(context),
          ),
        ],
      ),
    );
  }
}
