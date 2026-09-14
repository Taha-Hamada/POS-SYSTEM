import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_dropdown.dart';
import '../controllers/returns_controller.dart';
import '../../../theme/app_theme.dart';

/// اختيار سبب الإرجاع — إلزامي قبل التأكيد.
class ReturnsReasonField extends StatelessWidget {
  const ReturnsReasonField({super.key});

  @override
  Widget build(BuildContext context) {
    final ReturnsController returns = context.watch<ReturnsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'سبب الإرجاع',
              style: AppText.label.copyWith(fontSize: 12.5),
            ),
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppDropdown<String?>(
          value: returns.reason,
          width: double.infinity,
          height: 48,
          icon: Icons.help_outline_rounded,
          hint: 'اختر السبب…',
          onChanged: returns.setReason,
          items: <AppDropdownItem<String?>>[
            for (final String r in kReturnReasons)
              AppDropdownItem<String?>(value: r, label: r),
          ],
        ),
        if (returns.needsReason) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'لازم تختار سبب الإرجاع قبل التأكيد',
            style: AppText.caption.copyWith(
              fontSize: 11.5,
              color: AppColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}
