import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import 'quantity_stepper_button.dart';

/// عدّاد الكمية في سطر السلة.
///
/// الرقم نفسه خانة إدخال: الأزرار للزيادة والنقصان بواحد، والكتابة بالإيد
/// للأصناف اللي بتتباع بالكيلو أو اللتر (2.5 كيلو مثلًا).
class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onTyped,
  });

  final double quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  /// بترجّع false لو الكمية اترفضت (أكبر من الرصيد) عشان نرجّع النص القديم.
  final bool Function(double) onTyped;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late final TextEditingController _controller = TextEditingController(
    text: Fmt.qty(widget.quantity),
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // الخروج من الخانة بيثبّت الكمية، زي ما الضغط على Enter بيعمل.
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      } else {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(QuantityStepper old) {
    super.didUpdateWidget(old);

    // الأزرار أو السطر اتغيّروا من برّه — بنزامن النص، إلا لو المستخدم
    // بيكتب دلوقتي فمش هنقطع عليه.
    if (!_focus.hasFocus && widget.quantity != old.quantity) {
      _controller.text = Fmt.qty(widget.quantity);
    }
  }

  void _commit() {
    final double? typed = double.tryParse(_controller.text.trim());

    // قيمة مش مفهومة أو مرفوضة بترجّع الرقم اللي كان.
    if (typed == null || !widget.onTyped(typed)) {
      _controller.text = Fmt.qty(widget.quantity);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          QuantityStepperButton(
            icon: Icons.remove_rounded,
            onTap: widget.onDecrement,
            tooltip: 'تقليل',
          ),
          SizedBox(
            width: 46,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onSubmitted: (_) => _commit(),
              style: AppText.amountSm.copyWith(fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          QuantityStepperButton(
            icon: Icons.add_rounded,
            onTap: widget.onIncrement,
            tooltip: 'زيادة',
            accent: true,
          ),
        ],
      ),
    );
  }
}
