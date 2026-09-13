import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/shift_controller.dart';

/// فوتر حوار الإغلاق: ملخّص الوردية وأزرار الطباعة والإغلاق.
class CloseShiftFooter extends StatelessWidget {
  const CloseShiftFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final ShiftController shift = context.watch<ShiftController>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(AppRadius.xl),
          bottomLeft: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    '${Fmt.count(shift.totals.invoicesCount)} فاتورة • '
                    'رصيد افتتاحي ${Fmt.money(shift.opening)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          SecondaryButton(
            label: 'طباعة تقرير الوردية',
            icon: Icons.print_outlined,
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.md),
          PrimaryButton(
            label: 'إغلاق الوردية',
            icon: Icons.lock_outline_rounded,
            size: AppButtonSize.large,
            color: AppColors.warning,
            // بيرجّع المبلغ المعدود عشان اللي فتح الحوار يبعته للسيرفر.
            onPressed: shift.isCounted
                ? () => Navigator.of(context).pop(shift.actual)
                : null,
          ),
        ],
      ),
    );
  }
}
