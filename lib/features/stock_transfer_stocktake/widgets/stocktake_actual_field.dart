import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// خانة إدخال الكمية الفعلية — فاضية يعني الصنف لسه ماتجردش.
class StocktakeActualField extends StatefulWidget {
  const StocktakeActualField({
    super.key,
    required this.value,
    required this.fillColor,
    required this.onChanged,
  });

  final double? value;
  final Color fillColor;
  final ValueChanged<double?> onChanged;

  @override
  State<StocktakeActualField> createState() => _StocktakeActualFieldState();
}

class _StocktakeActualFieldState extends State<StocktakeActualField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value == null ? '' : Fmt.qty(widget.value!),
  );

  @override
  void didUpdateWidget(StocktakeActualField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // بيتزامن مع «مطابقة النظام» و«تفريغ الإدخالات»
    final String expected = widget.value == null ? '' : Fmt.qty(widget.value!);
    if (_controller.text != expected) _controller.text = expected;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        onChanged: (String v) =>
            widget.onChanged(v.trim().isEmpty ? null : double.tryParse(v)),
        style: AppText.amountSm.copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: '—',
          hintStyle: AppText.caption.copyWith(fontSize: 13),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
          ),
          fillColor: widget.fillColor,
        ),
      ),
    );
  }
}
