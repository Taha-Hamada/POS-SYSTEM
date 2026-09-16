import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/promotion_form_controller.dart';

/// أزرار الإلغاء والحفظ في حوار العرض، والسبب لو الزرار مقفول أو السيرفر رفض.
class CreatePromotionActions extends StatelessWidget {
  const CreatePromotionActions({super.key, required this.onSubmit});

  final PromotionSubmit onSubmit;

  Future<void> _submit(BuildContext context) async {
    final PromotionFormController form = context
        .read<PromotionFormController>();

    final bool saved = await form.submit(onSubmit);
    if (saved && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final PromotionFormController form = context
        .watch<PromotionFormController>();
    final String? message = form.error ?? form.problem;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (message != null) ...<Widget>[
          Row(
            children: <Widget>[
              Icon(
                form.error != null
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: form.error != null
                    ? AppColors.danger
                    : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppText.caption.copyWith(
                    color: form.error != null ? AppColors.danger : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
                    : 'إنشاء العرض',
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
