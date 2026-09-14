import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../models/return_line.dart';

/// خلية الصنف في صف المرتجع: أيقونة + الاسم والـSKU وسعر الوحدة.
class ReturnProductCell extends StatelessWidget {
  const ReturnProductCell({super.key, required this.line, this.index = 0});

  final ReturnLine line;

  /// ترتيب السطر — بيحدد لونه، لأن سطر الفاتورة مالوش أيقونة قسم.
  final int index;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        AppColors.productPalette[index % AppColors.productPalette.length];

    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 17,
            color: accent,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                line.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMedium.copyWith(fontSize: 13),
              ),
              Text(
                '${line.sku} • ${Fmt.money(line.unitPrice)}',
                style: AppText.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
