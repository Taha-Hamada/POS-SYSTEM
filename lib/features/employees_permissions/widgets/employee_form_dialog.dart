import 'package:flutter/material.dart';

import '../../../core/models/branch.dart';
import '../../../core/models/employee.dart';
import '../../../core/models/user_role.dart';
import '../../../theme/app_theme.dart';

/// بيانات الموظف الراجعة من الحوار.
///
/// [password] بيتبعت مع الإضافة بس — تغيير كلمة السر ليه حوار لوحده
/// عشان متتغيرش بالغلط مع تعديل عادي.
typedef EmployeeInput = ({
  String name,
  String username,
  String? password,
  String role,
  String? branchId,
  String phone,
  String? email,
  double salary,
});

/// بيبعت البيانات للسيرفر ويرجّع رسالة الخطأ لو رفض.
typedef EmployeeSubmit = Future<String?> Function(EmployeeInput input);

/// حوار إضافة موظف أو تعديل بياناته. بيرجّع true لو اتحفظ.
Future<bool?> showEmployeeFormDialog(
  BuildContext context, {
  required List<Branch> branches,
  required EmployeeSubmit onSubmit,
  Employee? initial,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _EmployeeFormDialog(
      branches: branches,
      onSubmit: onSubmit,
      initial: initial,
    ),
  );
}

class _EmployeeFormDialog extends StatefulWidget {
  const _EmployeeFormDialog({
    required this.branches,
    required this.onSubmit,
    this.initial,
  });

  final List<Branch> branches;
  final EmployeeSubmit onSubmit;
  final Employee? initial;

  @override
  State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<_EmployeeFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name,
  );
  late final TextEditingController _username = TextEditingController(
    text: widget.initial?.username,
  );
  final TextEditingController _password = TextEditingController();
  late final TextEditingController _phone = TextEditingController(
    text: widget.initial?.phone,
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.initial?.email,
  );
  late final TextEditingController _salary = TextEditingController(
    text: widget.initial == null
        ? '0'
        : widget.initial!.salary.toStringAsFixed(0),
  );

  late String _role = widget.initial?.role ?? UserRole.cashier.apiValue;

  /// الفرع المحفوظ ممكن يكون اتعطّل، فبنبدأ بيه بس لو لسه في القايمة.
  late String? _branchId =
      widget.branches.any((Branch b) => b.id == widget.initial?.branchId)
      ? widget.initial?.branchId
      : null;

  bool _saving = false;
  String? _error;

  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9._-]+$');

  bool get _editing => widget.initial != null;

  /// مدير النظام بس اللي ممكن يبقى من غير فرع، زي قاعدة السيرفر.
  bool get _needsBranch => _role != UserRole.admin.apiValue;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    _phone.dispose();
    _email.dispose();
    _salary.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final String email = _email.text.trim();

    final String? failure = await widget.onSubmit((
      name: _name.text.trim(),
      username: _username.text.trim().toLowerCase(),
      password: _editing ? null : _password.text,
      role: _role,
      branchId: _needsBranch ? _branchId : null,
      phone: _phone.text.trim(),
      email: email.isEmpty ? null : email,
      salary: double.tryParse(_salary.text.trim()) ?? 0,
    ));

    if (!mounted) return;

    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _error = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'تعديل بيانات الموظف' : 'موظف جديد'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                  validator: (String? v) => (v == null || v.trim().length < 2)
                      ? 'اكتب اسم الموظف'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _username,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'اسم الدخول',
                          helperText: 'حروف إنجليزية صغيرة وأرقام',
                        ),
                        validator: (String? v) {
                          final String value = v?.trim().toLowerCase() ?? '';
                          if (value.length < 3) return 'قصير جدًا';
                          return _usernamePattern.hasMatch(value)
                              ? null
                              : 'حروف إنجليزية وأرقام و . _ - بس';
                        },
                      ),
                    ),
                    if (!_editing) ...<Widget>[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _password,
                          obscureText: true,
                          textDirection: TextDirection.ltr,
                          decoration: const InputDecoration(
                            labelText: 'كلمة السر',
                            helperText: '8 حروف على الأقل',
                          ),
                          validator: (String? v) => (v == null || v.length < 8)
                              ? '8 حروف على الأقل'
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _role,
                        // من غير isExpanded الأسماء الطويلة بتخرج برّه الحقل.
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'الدور'),
                        items: <DropdownMenuItem<String>>[
                          for (final UserRole r in UserRole.values)
                            DropdownMenuItem<String>(
                              value: r.apiValue,
                              child: Text(r.label),
                            ),
                        ],
                        onChanged: (String? value) {
                          if (value != null) setState(() => _role = value);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _branchId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'الفرع',
                          helperText: _needsBranch
                              ? null
                              : 'مدير النظام على كل الفروع',
                        ),
                        items: <DropdownMenuItem<String?>>[
                          if (!_needsBranch)
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('كل الفروع'),
                            ),
                          for (final Branch b in widget.branches)
                            DropdownMenuItem<String?>(
                              value: b.id,
                              child: Text(b.name),
                            ),
                        ],
                        onChanged: _needsBranch
                            ? (String? value) =>
                                  setState(() => _branchId = value)
                            : null,
                        validator: (String? v) => _needsBranch && v == null
                            ? 'الدور ده لازم يتربط بفرع'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'الموبايل (اختياري)',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _salary,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الراتب الشهري',
                        ),
                        validator: (String? v) {
                          final double? value = double.tryParse(
                            v?.trim() ?? '',
                          );
                          return value == null || value < 0
                              ? 'رقم غير صالح'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'البريد (اختياري)',
                  ),
                  validator: (String? v) {
                    final String value = v?.trim() ?? '';
                    if (value.isEmpty) return null;
                    return value.contains('@') ? null : 'بريد غير صالح';
                  },
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'جاري الحفظ…' : 'حفظ'),
        ),
      ],
    );
  }
}

/// حوار إعادة تعيين كلمة السر. بيرجّع كلمة السر الجديدة.
Future<String?> showResetPasswordDialog(
  BuildContext context, {
  required Employee employee,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ResetPasswordDialog(employee: employee),
  );
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.employee});

  final Employee employee;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إعادة تعيين كلمة السر'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'كل جلسات «${widget.employee.name}» المفتوحة هتتقفل، '
                'ولازم يدخل بكلمة السر الجديدة.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _password,
                autofocus: true,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'كلمة السر الجديدة',
                ),
                validator: (String? v) =>
                    (v == null || v.length < 8) ? '8 حروف على الأقل' : null,
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
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(_password.text);
          },
          child: const Text('تغيير'),
        ),
      ],
    );
  }
}
