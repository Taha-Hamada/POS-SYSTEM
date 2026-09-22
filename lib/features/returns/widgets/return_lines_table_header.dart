import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/returns_controller.dart';
import '../models/return_accent.dart';

/// رأس جدول الأصناف — فيه Checkbox اختيار الكل.
class ReturnLinesTableHeader extends StatelessWidget {
  const ReturnLinesTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ReturnsController returns = context.watch<ReturnsController>();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 720;

          if (compact) {
            return Row(
              children: <Widget>[
                SizedBox(
                  width: 48,
                  child: Checkbox(
                    value: returns.allSelected,
                    tristate: true,
                    activeColor: kReturnAccent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (bool? v) => returns.setAllSelected(v ?? false),
                  ),
                ),
                Expanded(
                  child: Text(
                    'أصناف المرتجع',
                    style: AppText.label,
                  ),
                ),
              ],
            );
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 760),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 48,
                  child: Checkbox(
                    value: returns.allSelected,
                    tristate: true,
                    activeColor: kReturnAccent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (bool? v) => returns.setAllSelected(v ?? false),
                  ),
                ),
                Expanded(flex: 4, child: Text('الصنف', style: AppText.label)),
                SizedBox(
                  width: 110,
                  child: Text(
                    'الكمية المباعة',
                    style: AppText.label,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Text(
                    'الكمية المرتجعة',
                    style: AppText.label,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'قيمة الاسترداد',
                    style: AppText.label,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
