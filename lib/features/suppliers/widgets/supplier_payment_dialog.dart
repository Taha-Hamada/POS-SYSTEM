import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/supplier.dart';
import '../../../core/widgets/app_form_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// بيسأل عن مبلغ السداد للمورد ويرجّعه، أو `null` لو اتلغى.
Future<double?> showSupplierPaymentDialog(
  BuildContext context,
  Supplier supplier,
) {
  return showDialog<double>(
    context: context,
    builder: (BuildContext context) => _SupplierPaymentDialog(supplier: supplier),
  );
}

class _SupplierPaymentDialog extends StatefulWidget {
  const _SupplierPaymentDialog({required this.supplier});

  final Supplier supplier;

  @override
  State<_SupplierPaymentDialog> createState() => _SupplierPaymentDialogState();
}

class _SupplierPaymentDialogState extends State<_SupplierPaymentDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.supplier.balanceDue.toStringAsFixed(2),
  );

  double get _value => double.tryParse(_amount.text.trim()) ?? 0;

  /// السيرفر بيرفض مبلغ أكبر من المستحق، فبنمنعه من هنا.
  bool get _exceedsDue => _value > widget.supplier.balanceDue;
  bool get _canSubmit => _value > 0 && !_exceedsDue;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Supplier s = widget.supplier;

    return Dialog(
      child: SizedBox(
        width: 460,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('تسجيل دفعة للمورد', style: AppText.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${s.name} — المستحق ${Fmt.money(s.balanceDue)}',
                style: AppText.caption,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppFormField(
                label: 'المبلغ',
                controller: _amount,
                hint: '0.00',
                required: true,
                suffixText: Fmt.currencySymbol,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: (_) => setState(() {}),
              ),
              if (_exceedsDue) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'المبلغ أكبر من المستحق على الشركة.',
                  style: AppText.caption.copyWith(color: AppColors.danger),
                ),
              ],
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
                    flex: 2,
                    child: PrimaryButton(
                      label: 'تسجيل السداد',
                      icon: Icons.payments_outlined,
                      expanded: true,
                      onPressed: _canSubmit
                          ? () => Navigator.of(context).pop(_value)
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
