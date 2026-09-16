import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/session/session_controller.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../theme/app_theme.dart';

/// تغيير كلمة سر الحساب الحالي. بيرجّع true لو اتغيرت.
Future<bool?> showChangePasswordDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ChangeNotifierProvider<SessionController>.value(
      value: context.read<SessionController>(),
      child: const ChangePasswordDialog(),
    ),
  );
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _obscure = true;
  bool _saving = false;
  String? _error;

  /// نفس قاعدة السيرفر، عشان الغلط يبان قبل ما الطلب يتبعت.
  String? get _validation {
    if (_current.text.isEmpty) return 'اكتب كلمة السر الحالية';
    if (_next.text.length < 8) return 'كلمة السر الجديدة 8 حروف على الأقل';
    if (_next.text == _current.text) {
      return 'كلمة السر الجديدة لازم تكون مختلفة';
    }
    if (_confirm.text != _next.text) return 'تأكيد كلمة السر مش مطابق';
    return null;
  }

  Future<void> _save() async {
    final String? invalid = _validation;
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final String? error = await context
        .read<SessionController>()
        .changePassword(
          currentPassword: _current.text,
          newPassword: _next.text,
        );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: TextField(
      controller: controller,
      obscureText: _obscure,
      enabled: !_saving,
      decoration: InputDecoration(labelText: label),
      onSubmitted: (_) => _save(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تغيير كلمة السر'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'كل الأجهزة التانية اللي داخلة بحسابك هتخرج بعد التغيير.',
              style: AppText.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            _field('كلمة السر الحالية', _current),
            _field('كلمة السر الجديدة', _next),
            _field('تأكيد كلمة السر الجديدة', _confirm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                label: Text(_obscure ? 'إظهار' : 'إخفاء'),
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        PrimaryButton(
          label: _saving ? 'بيتحفظ…' : 'حفظ',
          size: AppButtonSize.small,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
