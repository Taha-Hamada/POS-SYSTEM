import 'package:flutter/material.dart';

import '../../../core/models/expense.dart';
import '../../../core/widgets/app_form_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// بيسأل عن سبب رفض المصروف ويرجّعه، أو `null` لو اتلغى.
///
/// السيرفر بيرفض الرفض من غير سبب، فالسبب مطلوب هنا مش اختياري.
Future<String?> showRejectExpenseDialog(BuildContext context, Expense expense) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => _RejectExpenseDialog(expense: expense),
  );
}

class _RejectExpenseDialog extends StatefulWidget {
  const _RejectExpenseDialog({required this.expense});

  final Expense expense;

  @override
  State<_RejectExpenseDialog> createState() => _RejectExpenseDialogState();
}

class _RejectExpenseDialogState extends State<_RejectExpenseDialog> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Expense e = widget.expense;
    final bool canSubmit = _reason.text.trim().isNotEmpty;

    return Dialog(
      child: SizedBox(
        width: 460,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('رفض المصروف ${e.number}', style: AppText.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${e.category} — ${Fmt.money(e.amount)}',
                style: AppText.caption,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppFormField(
                label: 'سبب الرفض',
                controller: _reason,
                hint: 'مثال: مفيش فاتورة مرفقة',
                required: true,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SecondaryButton(
                      label: 'إلغاء',
                      expanded: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'رفض',
                      icon: Icons.close_rounded,
                      color: AppColors.danger,
                      expanded: true,
                      onPressed: canSubmit
                          ? () => Navigator.of(context).pop(_reason.text.trim())
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
