import 'package:flutter/material.dart';

import '../../../core/models/loyalty_tier.dart';
import '../../../theme/app_theme.dart';

/// حوار تعديل مستوى — بيرجّع المستوى بعد التعديل أو null لو اتلغى.
///
/// التعديل بيفضل محلي لحد ما المدير يضغط «حفظ الإعدادات»، عشان يقدر
/// يظبط المستويات التلاتة مع بعض والحدود تفضل تصاعدية.
Future<LoyaltyTier?> showLoyaltyTierDialog(
  BuildContext context,
  LoyaltyTier tier,
) {
  return showDialog<LoyaltyTier>(
    context: context,
    builder: (_) => _LoyaltyTierDialog(tier: tier),
  );
}

class _LoyaltyTierDialog extends StatefulWidget {
  const _LoyaltyTierDialog({required this.tier});

  final LoyaltyTier tier;

  @override
  State<_LoyaltyTierDialog> createState() => _LoyaltyTierDialogState();
}

class _LoyaltyTierDialogState extends State<_LoyaltyTierDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name = TextEditingController(
    text: widget.tier.name,
  );
  late final TextEditingController _minPurchases = TextEditingController(
    text: widget.tier.minPurchases.toStringAsFixed(0),
  );
  late final TextEditingController _discount = TextEditingController(
    text: _number(widget.tier.discountPercent),
  );
  late final TextEditingController _benefits = TextEditingController(
    text: widget.tier.benefits.join('\n'),
  );

  static String _number(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  @override
  void dispose() {
    _name.dispose();
    _minPurchases.dispose();
    _discount.dispose();
    _benefits.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      widget.tier.copyWith(
        name: _name.text.trim(),
        minPurchases: double.parse(_minPurchases.text.trim()),
        discountPercent: double.parse(_discount.text.trim()),
        // كل سطر ميزة، والسطور الفاضية بتتشال.
        benefits: _benefits.text
            .split('\n')
            .map((String line) => line.trim())
            .where((String line) => line.isNotEmpty)
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تعديل مستوى «${widget.tier.name}»'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'اسم المستوى'),
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? 'اكتب اسم المستوى' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _minPurchases,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'من إجمالي مشتريات',
                        suffixText: 'ج.م',
                      ),
                      validator: (String? v) {
                        final double? value = double.tryParse(v?.trim() ?? '');
                        return value == null || value < 1
                            ? 'رقم أكبر من صفر'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _discount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'خصم تلقائي',
                        suffixText: '%',
                      ),
                      validator: (String? v) {
                        final double? value = double.tryParse(v?.trim() ?? '');
                        return value == null || value < 0 || value > 100
                            ? 'بين 0 و 100'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _benefits,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'المزايا',
                  helperText: 'كل ميزة في سطر',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('تم')),
      ],
    );
  }
}
