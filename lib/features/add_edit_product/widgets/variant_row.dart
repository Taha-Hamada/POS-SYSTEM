import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/product_variant.dart';
import 'variant_cell_field.dart';

/// صف واحد في جدول المتغيرات.
class VariantRow extends StatelessWidget {
  const VariantRow({
    super.key,
    required this.variant,
    required this.isLast,
    required this.canRemove,
    required this.onRemove,
  });

  final ProductVariant variant;
  final bool isLast;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: VariantCellField(
              hint: 'M / L / XL',
              initial: variant.size,
              onChanged: (String v) => variant.size = v,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: VariantCellField(
              hint: 'أحمر / أزرق',
              initial: variant.color,
              onChanged: (String v) => variant.color = v,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: VariantCellField(
              hint: 'SKU-001',
              initial: variant.sku,
              onChanged: (String v) => variant.sku = v,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: VariantCellField(
              hint: 'سعر المنتج',
              initial: variant.price,
              numeric: true,
              onChanged: (String v) => variant.price = v,
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              tooltip: 'حذف الصف',
              onPressed: canRemove ? onRemove : null,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: AppColors.textMuted,
              hoverColor: AppColors.dangerSoft,
            ),
          ),
        ],
      ),
    );
  }
}
