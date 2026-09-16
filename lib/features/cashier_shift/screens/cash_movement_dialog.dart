import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// حركة كاش يدوية على الدرج.
typedef CashMovementInput = ({bool isIn, double amount, String reason});

/// أسباب شائعة للاختيار السريع.
const Map<bool, List<String>> kCashReasons = <bool, List<String>>{
  true: <String>['فكة للدرج', 'تغذية من الخزنة', 'تحصيل من عميل'],
  false: <String>['توريد للخزنة', 'مصروف نثري', 'فكة لفرع تاني'],
};

/// إيداع أو سحب من درج الوردية. بيرجّع الحركة أو null لو اتلغت.
///
/// [expectedCash] الموجود في الدرج دلوقتي، عشان الكاشير يشوف السحب مش
/// أكبر من اللي معاه.
Future<CashMovementInput?> showCashMovementDialog(
  BuildContext context, {
  required double expectedCash,
}) {
  return showDialog<CashMovementInput>(
    context: context,
    builder: (_) => CashMovementDialog(expectedCash: expectedCash),
  );
}

class CashMovementDialog extends StatefulWidget {
  const CashMovementDialog({super.key, required this.expectedCash});

  final double expectedCash;

  @override
  State<CashMovementDialog> createState() => _CashMovementDialogState();
}

class _CashMovementDialogState extends State<CashMovementDialog> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _reason = TextEditingController();

  bool _isIn = false;

  double get _value => double.tryParse(_amount.text.trim()) ?? 0;

  String? get _problem {
    if (_value <= 0) return 'اكتب المبلغ';
    if (!_isIn && _value > widget.expectedCash + 0.005) {
      return 'السحب أكبر من الموجود في الدرج '
          '(${Fmt.money(widget.expectedCash)})';
    }
    if (_reason.text.trim().length < 2) return 'اكتب سبب الحركة';
    return null;
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (_problem != null) return;
    Navigator.of(
      context,
    ).pop((isIn: _isIn, amount: _value, reason: _reason.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final String? problem = _problem;
    final bool touched = _amount.text.isNotEmpty;

    return AlertDialog(
      title: const Text('حركة كاش على الدرج'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  label: Text('سحب من الدرج'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('إيداع في الدرج'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
              ],
              selected: <bool>{_isIn},
              onSelectionChanged: (Set<bool> v) =>
                  setState(() => _isIn = v.first),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'في الدرج دلوقتي: ${Fmt.money(widget.expectedCash)}',
              style: AppText.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(labelText: 'المبلغ'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reason,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'السبب'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final String r in kCashReasons[_isIn]!)
                  ActionChip(
                    label: Text(r),
                    onPressed: () => setState(() => _reason.text = r),
                  ),
              ],
            ),
            if (touched && problem != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(problem, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        PrimaryButton(
          label: _isIn ? 'تسجيل الإيداع' : 'تسجيل السحب',
          size: AppButtonSize.small,
          onPressed: problem == null ? _submit : null,
        ),
      ],
    );
  }
}
