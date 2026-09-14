import 'package:flutter/material.dart';

import '../../../core/widgets/app_data_table.dart';
import '../../../core/models/supplier.dart';
import '../../../theme/app_theme.dart';

/// خلية المورد: أفاتار دائري + الاسم والإيميل.
class SupplierNameCell extends StatelessWidget {
  const SupplierNameCell({super.key, required this.supplier});

  final Supplier supplier;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.storefront_rounded,
            size: 18,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: TableCells.twoLine(
            supplier.name,
            supplier.email.isEmpty ? supplier.phone : supplier.email,
          ),
        ),
      ],
    );
  }
}
