import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// بيانات عميل جديد راجعة من الحوار.
typedef NewCustomer = ({
  String name,
  String phone,
  String? email,
});

/// حوار إضافة عميل.
///
/// بيجمّع البيانات ويرجّعها، والشاشة هي اللي بتبعت للسيرفر،
/// عشان الحوار مايبقاش عارف حاجة عن الشبكة.
Future<NewCustomer?> showCustomerFormDialog(BuildContext context) {
  return showDialog<NewCustomer>(
    context: context,
    builder: (_) => const _CustomerFormDialog(),
  );
}

class _CustomerFormDialog extends StatefulWidget {
  const _CustomerFormDialog();

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop((
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('عميل جديد'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'الاسم'),
                validator: (String? v) =>
                    (v == null || v.trim().length < 2) ? 'اكتب اسم العميل' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الموبايل'),
                validator: (String? v) =>
                    (v == null || v.trim().length < 7) ? 'رقم غير صالح' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد (اختياري)',
                ),
                validator: (String? v) {
                  final String value = v?.trim() ?? '';
                  if (value.isEmpty) return null;
                  return value.contains('@') ? null : 'بريد غير صالح';
                },
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
        FilledButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}

/// حوار تحصيل دفعة من عميل عليه مديونية.
Future<double?> showCollectPaymentDialog(
  BuildContext context, {
  required double debt,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _CollectPaymentDialog(debt: debt),
  );
}

class _CollectPaymentDialog extends StatefulWidget {
  const _CollectPaymentDialog({required this.debt});

  final double debt;

  @override
  State<_CollectPaymentDialog> createState() => _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends State<_CollectPaymentDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount =
      TextEditingController(text: widget.debt.toStringAsFixed(2));

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(double.parse(_amount.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تحصيل دفعة'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'المديونية الحالية ${widget.debt.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ المحصّل'),
                validator: (String? v) {
                  final double? value = double.tryParse(v?.trim() ?? '');
                  if (value == null || value <= 0) return 'مبلغ غير صالح';
                  // السيرفر بيرفض السداد الزيادة، فبنمنعه من هنا.
                  if (value > widget.debt) {
                    return 'المبلغ أكبر من المديونية';
                  }
                  return null;
                },
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
        FilledButton(onPressed: _submit, child: const Text('تحصيل')),
      ],
    );
  }
}
