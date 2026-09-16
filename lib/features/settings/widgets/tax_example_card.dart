import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/settings_controller.dart';

/// مثال حي على احتساب الضريبة لمنتج بـ100 ج.م.
class TaxExampleCard extends StatelessWidget {
  const TaxExampleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final double rate = settings.taxRate;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.calculate_outlined,
            size: 20,
            color: AppColors.accent,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'مثال على منتج بـ100 ج.م',
                  style: AppText.cardTitle.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 3),
                Text(
                  settings.taxIncluded
                      ? 'السعر المعروض 100 ج.م (منها '
                            '${Fmt.money(100 - 100 / (1 + rate / 100))} ضريبة)'
                      : 'السعر المعروض 100 ج.م + '
                            '${Fmt.money(100 * rate / 100)} ضريبة = '
                            '${Fmt.money(100 * (1 + rate / 100))}',
                  style: AppText.caption.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
