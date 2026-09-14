import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// رأس جدول المتغيرات.
class VariantsTableHeader extends StatelessWidget {
  const VariantsTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.md),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: Text('المقاس', style: AppText.label)),
          Expanded(child: Text('اللون', style: AppText.label)),
          Expanded(flex: 2, child: Text('SKU', style: AppText.label)),
          Expanded(child: Text('سعر خاص', style: AppText.label)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
