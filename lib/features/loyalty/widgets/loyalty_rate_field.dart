import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/loyalty_controller.dart';

/// خانة رقم في آلية الكسب (نقاط لكل جنيه أو قيمة النقطة).
class LoyaltyRateField extends StatelessWidget {
  const LoyaltyRateField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final LoyaltyController loyalty = context.read<LoyaltyController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: AppText.label.copyWith(fontSize: 12)),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 52,
          child: TextField(
            controller: controller,
            enabled: enabled,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: loyalty.rateChanged,
            style: AppText.amountLg.copyWith(fontSize: 20),
            decoration: InputDecoration(
              fillColor: AppColors.surfaceAlt,
              prefixIcon: Icon(icon, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
