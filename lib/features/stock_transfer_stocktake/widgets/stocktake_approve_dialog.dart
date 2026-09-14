import 'package:flutter/material.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/stocktake_controller.dart';
import 'stocktake_summary_line.dart';

/// بيطلب تأكيد اعتماد الجرد — بيرجّع true لو المستخدم أكّد.
Future<bool?> showStocktakeApproveDialog(
  BuildContext context,
  StocktakeController stocktake,
) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) =>
        StocktakeApproveDialog(stocktake: stocktake),
  );
}

class StocktakeApproveDialog extends StatelessWidget {
  const StocktakeApproveDialog({super.key, required this.stocktake});

  final StocktakeController stocktake;

  @override
  Widget build(BuildContext context) {
    final double netValue = stocktake.netValue;

    return AlertDialog(
      title: const Text('اعتماد الجرد'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'سيتم ترحيل الفروقات وتعديل أرصدة المخزون في '
              '${stocktake.branchName}.',
              style: AppText.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            StocktakeSummaryLine(
              label: 'أصناف تم جردها',
              value: Fmt.count(stocktake.countedCount),
            ),
            StocktakeSummaryLine(
              label: 'أصناف بها عجز',
              value: Fmt.count(stocktake.shortageCount),
              color: AppColors.danger,
            ),
            StocktakeSummaryLine(
              label: 'أصناف بها زيادة',
              value: Fmt.count(stocktake.surplusCount),
              color: AppColors.success,
            ),
            StocktakeSummaryLine(
              label: 'صافي فرق القيمة',
              value: Fmt.money(netValue),
              color: netValue < 0 ? AppColors.danger : AppColors.success,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        PrimaryButton(
          label: 'اعتماد',
          size: AppButtonSize.small,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
