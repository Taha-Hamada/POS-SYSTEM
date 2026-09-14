import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/supplier.dart';
import '../../../core/widgets/app_form_field.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../data/suppliers_repository.dart';

/// يفتح نموذج إضافة أو تعديل مورد ويرجّع اللي السيرفر قبله.
///
/// [existing] لو اتبعت، النموذج بيبقى تعديل بدل إضافة.
Future<Supplier?> showSupplierFormDialog(
  BuildContext context, {
  Supplier? existing,
}) {
  final SuppliersRepository repository =
      SuppliersRepository(context.read<ApiClient>());

  return showDialog<Supplier>(
    context: context,
    builder: (BuildContext context) => _SupplierFormDialog(
      repository: repository,
      existing: existing,
    ),
  );
}

class _SupplierFormDialog extends StatefulWidget {
  const _SupplierFormDialog({required this.repository, this.existing});

  final SuppliersRepository repository;
  final Supplier? existing;

  @override
  State<_SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<_SupplierFormDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final TextEditingController _contact =
      TextEditingController(text: widget.existing?.contactPerson ?? '');
  late final TextEditingController _email =
      TextEditingController(text: widget.existing?.email ?? '');
  late final TextEditingController _address =
      TextEditingController(text: widget.existing?.address ?? '');
  late final TextEditingController _taxNumber =
      TextEditingController(text: widget.existing?.taxNumber ?? '');
  late final TextEditingController _terms = TextEditingController(
    text: (widget.existing?.paymentTermDays ?? 0).toString(),
  );

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  /// السيرفر بيطلب اسم من حرفين ورقم موبايل من سبع خانات على الأقل.
  bool get _canSave =>
      !_saving &&
      _name.text.trim().length >= 2 &&
      _phone.text.trim().length >= 7;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _contact.dispose();
    _email.dispose();
    _address.dispose();
    _taxNumber.dispose();
    _terms.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final Supplier saved = _isEdit
          ? await widget.repository.update(
              widget.existing!.id,
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              contactPerson: _contact.text.trim(),
              email: _email.text.trim(),
              address: _address.text.trim(),
              taxNumber: _taxNumber.text.trim(),
              paymentTermDays: int.tryParse(_terms.text.trim()) ?? 0,
            )
          : await widget.repository.create(
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              contactPerson: _contact.text.trim(),
              email: _email.text.trim(),
              address: _address.text.trim(),
              taxNumber: _taxNumber.text.trim(),
              paymentTermDays: int.tryParse(_terms.text.trim()) ?? 0,
            );

      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (exception) {
      if (!mounted) return;

      setState(() => _saving = false);
      showPlainSnackBar(
        context,
        exception.fieldErrors['phone'] ?? exception.message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _isEdit ? 'تعديل بيانات المورد' : 'مورد جديد',
                      style: AppText.sectionTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: AppFormField(
                      label: 'اسم المورد',
                      controller: _name,
                      hint: 'مثال: شركة النور للتوريدات',
                      required: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppFormField(
                      label: 'رقم الموبايل',
                      controller: _phone,
                      hint: '01012345678',
                      required: true,
                      keyboardType: TextInputType.phone,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: AppFormField(
                      label: 'مسؤول التواصل',
                      controller: _contact,
                      hint: 'اختياري',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppFormField(
                      label: 'البريد الإلكتروني',
                      controller: _email,
                      hint: 'اختياري',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: AppFormField(
                      label: 'الرقم الضريبي',
                      controller: _taxNumber,
                      hint: 'اختياري',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppFormField(
                      label: 'مهلة السداد (بالأيام)',
                      controller: _terms,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppFormField(
                label: 'العنوان',
                controller: _address,
                hint: 'اختياري',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SecondaryButton(
                      label: 'إلغاء',
                      expanded: true,
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: _saving
                          ? 'بنحفظ…'
                          : (_isEdit ? 'حفظ التعديلات' : 'إضافة المورد'),
                      icon: Icons.check_rounded,
                      expanded: true,
                      onPressed: _canSave ? _save : null,
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
