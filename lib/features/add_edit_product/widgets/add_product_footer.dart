import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/product.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/product_form_controller.dart';
import '../models/product_form_tab.dart';

/// الشريط السفلي الثابت: حالة النموذج وأزرار الإلغاء والحفظ.
class AddProductFooter extends StatelessWidget {
  const AddProductFooter({super.key});

  /// بيتأكد من الحقول اللي السيرفر بيرفض من غيرها، وبيودّي المستخدم للتبويب
  /// اللي فيه النقص بدل ما يسيبه يدوّر.
  bool _guard(BuildContext context, ProductFormController form) {
    if (!form.hasName) {
      form.goToTab(ProductFormTab.basic);
      showPlainSnackBar(context, 'من فضلك أدخل اسم المنتج أولاً');
      return false;
    }

    if (!form.hasSku) {
      form.goToTab(ProductFormTab.basic);
      showPlainSnackBar(context, 'كود المنتج (SKU) مطلوب');
      return false;
    }

    if (form.categoryId == null) {
      form.goToTab(ProductFormTab.basic);
      showPlainSnackBar(context, 'اختر فئة المنتج');
      return false;
    }

    if (form.isLoss) {
      form.goToTab(ProductFormTab.pricing);
      showPlainSnackBar(context, 'التكلفة أعلى من سعر البيع');
      return false;
    }

    return true;
  }

  Future<void> _save(BuildContext context) async {
    final ProductFormController form = context.read<ProductFormController>();
    if (!_guard(context, form)) return;

    final Product? saved = await form.save();
    if (!context.mounted) return;

    if (saved == null) {
      showPlainSnackBar(context, form.saveError ?? 'مقدرناش نحفظ المنتج');
      return;
    }

    showPlainSnackBar(context, 'تم حفظ «${saved.name}»');
    context.go('/products');
  }

  @override
  Widget build(BuildContext context) {
    final ProductFormController form = context.watch<ProductFormController>();
    final bool ready = form.canSave;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(
            ready
                ? Icons.check_circle_outline_rounded
                : Icons.edit_note_rounded,
            size: 18,
            color: ready ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              _statusText(form),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(fontSize: 12.5),
            ),
          ),
          const Spacer(),
          SecondaryButton(
            label: 'إلغاء',
            size: AppButtonSize.large,
            onPressed: () => context.go('/products'),
          ),
          const SizedBox(width: AppSpacing.md),
          PrimaryButton(
            label: form.isLoading ? 'بنحفظ…' : 'حفظ المنتج',
            icon: Icons.save_outlined,
            size: AppButtonSize.large,
            onPressed: form.isLoading ? null : () => _save(context),
          ),
        ],
      ),
    );
  }

  String _statusText(ProductFormController form) {
    if (form.isLoading) return 'بنحفظ المنتج على السيرفر…';
    if (!form.hasName) return 'لم يتم إدخال اسم المنتج بعد';
    if (!form.hasSku) return 'ناقص كود المنتج (SKU)';
    if (form.isLoss) return 'التكلفة أعلى من سعر البيع';
    return 'جاهز للحفظ: ${form.productName}';
  }
}
