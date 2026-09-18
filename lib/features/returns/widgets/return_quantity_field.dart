import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// خانة الكمية المرتجعة — بتتعطّل لو الصنف مش متحدد.
class ReturnQuantityField extends StatefulWidget {
  const ReturnQuantityField({
    super.key,
    required this.initialQuantity,
    required this.enabled,
    required this.onChanged,
  });

  final double initialQuantity;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<ReturnQuantityField> createState() => _ReturnQuantityFieldState();
}

class _ReturnQuantityFieldState extends State<ReturnQuantityField> {
  late final TextEditingController _controller =
      TextEditingController(text: Fmt.qty(widget.initialQuantity));

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
        enabled: widget.enabled,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        onChanged: (String v) => widget.onChanged(double.tryParse(v) ?? 0),
        style: AppText.amountSm.copyWith(fontSize: 13.5),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
          ),
          fillColor:
              widget.enabled ? AppColors.surface : AppColors.surfaceAlt,
        ),
      ),
    );
  }
}
