import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/product_profile_controller.dart';

/// شريط الحفظ أسفل تبويب البيانات.
class ProductSaveBar extends StatelessWidget {
  const ProductSaveBar({super.key});

  Future<void> _save(BuildContext context) async {
    final ProductProfileController products = context
        .read<ProductProfileController>();

    final String? error = await products.save();
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      error ?? 'اتحفظت تعديلات المنتج',
      isError: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProductProfileController p = context
        .watch<ProductProfileController>();

    // مفيش تعديل ولا خطأ معروض؟ الشريط مالوش لازمة.
    if (!p.isDirty && p.saveError == null) return const SizedBox.shrink();

    final String? blocked = p.problem;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(radius: AppRadius.lg),
      child: Row(
        children: <Widget>[
          Icon(
            p.saveError != null
                ? Icons.error_outline_rounded
                : Icons.edit_note_rounded,
            size: 20,
            color: p.saveError != null
                ? AppColors.danger
                : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              p.saveError ?? blocked ?? 'فيه تعديلات لسه ماتحفظتش',
              style: AppText.body.copyWith(
                fontSize: 13,
                color: p.saveError != null || blocked != null
                    ? AppColors.danger
                    : AppColors.textSecondary,
              ),
            ),
          ),
          SecondaryButton(
            label: 'تراجع',
            icon: Icons.undo_rounded,
            onPressed: p.isLoading ? null : p.discardChanges,
          ),
          const SizedBox(width: AppSpacing.md),
          PrimaryButton(
            label: 'حفظ التعديلات',
            icon: Icons.save_outlined,
            isLoading: p.isLoading,
            onPressed: p.canSave ? () => _save(context) : null,
          ),
        ],
      ),
    );
  }
}
