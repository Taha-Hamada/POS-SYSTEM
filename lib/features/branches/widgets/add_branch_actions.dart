import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/add_branch_controller.dart';

/// أزرار الإلغاء والحفظ في حوار الفرع، ورسالة السيرفر لو رفض.
class AddBranchActions extends StatelessWidget {
  const AddBranchActions({super.key, required this.onSubmit});

  final BranchSubmit onSubmit;

  Future<void> _submit(BuildContext context) async {
    final AddBranchController form = context.read<AddBranchController>();

    final bool saved = await form.submit(onSubmit);
    if (saved && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final AddBranchController form = context.watch<AddBranchController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (form.error != null) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    form.error!,
                    style: AppText.caption.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Row(
          children: <Widget>[
            Expanded(
              child: SecondaryButton(
                label: 'إلغاء',
                expanded: true,
                onPressed: form.saving
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: form.saving
                    ? 'جاري الحفظ…'
                    : form.isEditing
                    ? 'حفظ التعديلات'
                    : 'إضافة الفرع',
                icon: Icons.check_rounded,
                expanded: true,
                onPressed: form.isValid && !form.saving
                    ? () => _submit(context)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
