import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/supplier.dart';
import '../../../theme/app_theme.dart';
import '../controllers/create_purchase_order_controller.dart';

/// بيانات التواصل للمورد المختار.
class CreatePoSupplierContact extends StatelessWidget {
  const CreatePoSupplierContact({super.key});

  @override
  Widget build(BuildContext context) {
    final Supplier? supplier =
        context.watch<CreatePurchaseOrderController>().supplier;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.person_outline_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              supplier == null || supplier.contactPerson.isEmpty
                  ? 'مفيش مسؤول تواصل مسجّل'
                  : supplier.contactPerson,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body.copyWith(fontSize: 12.5),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.phone_outlined,
            size: 15,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 5),
          Text(
            supplier?.phone ?? '—',
            style: AppText.caption.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
