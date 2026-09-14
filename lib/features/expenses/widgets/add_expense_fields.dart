import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/models/branch.dart';
import '../../../core/models/payment_method.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_form_field.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/add_expense_controller.dart';

/// حقول نموذج المصروف: البند والمبلغ وطريقة الدفع والفرع والملاحظة.
class AddExpenseFields extends StatelessWidget {
  const AddExpenseFields({super.key});

  @override
  Widget build(BuildContext context) {
    final AddExpenseController form = context.watch<AddExpenseController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: AppFormField(
                label: 'بند المصروف',
                controller: form.categoryController,
                hint: 'مثال: كهرباء',
                required: true,
                onChanged: form.fieldChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppFormField(
                label: 'المبلغ',
                controller: form.amountController,
                hint: '0.00',
                required: true,
                suffixText: Fmt.currencySymbol,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: form.fieldChanged,
              ),
            ),
          ],
        ),
        if (form.knownCategories.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _CategorySuggestions(categories: form.knownCategories),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: LabeledField(
                label: 'طريقة الدفع',
                child: AppDropdown<PaymentMethod>(
                  value: form.method,
                  width: double.infinity,
                  height: 48,
                  icon: Icons.payments_outlined,
                  onChanged: form.setMethod,
                  items: <AppDropdownItem<PaymentMethod>>[
                    for (final PaymentMethod m in PaymentMethod.values)
                      if (m != PaymentMethod.credit)
                        AppDropdownItem<PaymentMethod>(
                          value: m,
                          label: m.label,
                          icon: m.icon,
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: LabeledField(
                label: 'الفرع',
                child: AppDropdown<String?>(
                  value: form.branchId,
                  width: double.infinity,
                  height: 48,
                  icon: Icons.store_outlined,
                  onChanged: form.setBranch,
                  items: <AppDropdownItem<String?>>[
                    for (final Branch b in form.branches)
                      AppDropdownItem<String?>(value: b.id, label: b.name),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // الكاش بيخرج من الدرج، فالسيرفر بيربطه بوردية اللي سجّله.
        if (form.method == PaymentMethod.cash)
          Text(
            'المصروف الكاش هيتخصم من درج ورديتك المفتوحة.',
            style: AppText.caption.copyWith(fontSize: 11.5),
          ),
        const SizedBox(height: AppSpacing.lg),
        AppFormField(
          label: 'ملاحظة',
          controller: form.noteController,
          hint: 'وصف مختصر للمصروف…',
          maxLines: 3,
        ),
      ],
    );
  }
}

/// البنود المستخدمة قبل كده — ضغطة بتملى الخانة بدل ما المستخدم يكتبها.
class _CategorySuggestions extends StatelessWidget {
  const _CategorySuggestions({required this.categories});

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    final AddExpenseController form = context.read<AddExpenseController>();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final String c in categories.take(8))
          ActionChip(
            label: Text(c, style: AppText.caption.copyWith(fontSize: 11.5)),
            onPressed: () => form.setCategory(c),
            visualDensity: VisualDensity.compact,
            side: const BorderSide(color: AppColors.border),
            backgroundColor: AppColors.surfaceAlt,
          ),
      ],
    );
  }
}
