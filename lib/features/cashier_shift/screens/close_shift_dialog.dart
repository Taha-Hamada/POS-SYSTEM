import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/shift.dart';
import '../../../theme/app_theme.dart';
import '../controllers/shift_controller.dart';
import '../widgets/close_shift_footer.dart';
import '../widgets/close_shift_header.dart';
import '../widgets/shift_count_field.dart';
import '../widgets/shift_difference_card.dart';
import '../widgets/shift_stat_cards.dart';

/// يفتح حوار إغلاق الوردية ويرجّع المبلغ المعدود (أو null لو اتلغى).
Future<double?> showCloseShiftDialog(
  BuildContext context, {
  required Shift shift,
  required ShiftTotals totals,
}) {
  return showDialog<double>(
    context: context,
    barrierColor: AppColors.primary.withValues(alpha: 0.55),
    builder: (_) => CloseShiftDialog(shift: shift, totals: totals),
  );
}

/// حوار إغلاق الوردية — بيجمّع الهيدر والإحصائيات وحقل العدّ وبطاقة الفرق.
class CloseShiftDialog extends StatelessWidget {
  const CloseShiftDialog({
    super.key,
    required this.shift,
    required this.totals,
  });

  final Shift shift;

  /// أرقام الوردية زي ما السيرفر حسبها.
  final ShiftTotals totals;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);

    return ChangeNotifierProvider<ShiftController>(
      create: (_) => ShiftController(
        openingBalance: shift.openingBalance,
        shift: shift,
        totals: totals,
      ),
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 860,
            maxHeight: screen.height - 80,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CloseShiftHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ShiftStatCards(),
                      SizedBox(height: AppSpacing.xl),
                      ShiftCountField(),
                      SizedBox(height: AppSpacing.lg),
                      ShiftDifferenceCard(),
                    ],
                  ),
                ),
              ),
              CloseShiftFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
