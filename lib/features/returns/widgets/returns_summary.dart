import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/returns_controller.dart';
import '../models/returnable_invoice.dart';
import '../models/return_accent.dart';
import 'returns_summary_row.dart';

/// ملخّص المرتجع وإجماليه وزرار التأكيد.
class ReturnsSummary extends StatelessWidget {
  const ReturnsSummary({super.key});

  Future<void> _submit(BuildContext context) async {
    final ReturnsController returns = context.read<ReturnsController>();

    final CompletedReturn? created = await returns.submit();
    if (!context.mounted) return;

    if (created == null) {
      // السبب متعرض في شريط الخطأ فوق، فبنكتفي بتنبيه مختصر.
      showAppSnackBar(context, returns.error ?? 'مقدرناش نسجّل المرتجع',
          isError: true);
      return;
    }

    showPlainSnackBar(
      context,
      'اتسجّل المرتجع ${created.number} بقيمة ${Fmt.money(created.total)} '
      '(${kRefundMethods[created.refundMethod] ?? created.refundMethod})',
      width: 520,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ReturnsController returns = context.watch<ReturnsController>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ReturnsSummaryRow(
            label: 'أصناف مختارة',
            value: '${Fmt.count(returns.selectedLines.length)} صنف • '
                '${Fmt.count(returns.returnedUnits)} وحدة',
          ),
          const SizedBox(height: AppSpacing.sm),
          ReturnsSummaryRow(
            label: 'قيمة الأصناف',
            value: Fmt.money(returns.refundSubtotal),
          ),
          const SizedBox(height: AppSpacing.sm),
          ReturnsSummaryRow(
            label: 'ضريبة مستردة '
                '(${(returns.taxRate * 100).toStringAsFixed(0)}%)',
            value: Fmt.money(returns.refundTax),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                'إجمالي المرتجع',
                style: AppText.sectionTitle.copyWith(fontSize: 15),
              ),
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    Fmt.money(returns.refundTotal),
                    style: AppText.amountHero.copyWith(
                      fontSize: 30,
                      color: kReturnAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'تأكيد المرتجع',
            icon: Icons.assignment_return_rounded,
            size: AppButtonSize.hero,
            expanded: true,
            color: kReturnAccent,
            onPressed: returns.canSubmit ? () => _submit(context) : null,
          ),
        ],
      ),
    );
  }
}
