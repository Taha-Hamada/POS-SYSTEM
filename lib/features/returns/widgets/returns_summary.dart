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

    // الرسالة بتفرّق بين اللي خرج كاش واللي اتسوّى على الحساب.
    final String breakdown = created.creditRefund > 0 && created.cashRefund > 0
        ? 'كاش ${Fmt.money(created.cashRefund)} و'
            '${Fmt.money(created.creditRefund)} على الحساب'
        : created.creditRefund > 0
        ? 'على حساب العميل'
        : 'كاش';

    showPlainSnackBar(
      context,
      'اتسجّل المرتجع ${created.number} بقيمة ${Fmt.money(created.total)} '
      '($breakdown)',
      width: 560,
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
                '${Fmt.qty(returns.returnedUnits)} وحدة',
          ),
          const SizedBox(height: AppSpacing.sm),
          ReturnsSummaryRow(
            label: 'قيمة الأصناف',
            value: Fmt.money(returns.refundSubtotal),
          ),
          // نصيب المرتجع من خصم الفاتورة — من غيره الرقم المعروض بيبقى
          // أعلى من اللي بيترد فعلًا.
          if (returns.refundDiscountShare > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            ReturnsSummaryRow(
              label: 'خصم الفاتورة',
              value: '− ${Fmt.money(returns.refundDiscountShare)}',
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ReturnsSummaryRow(
            label: 'ضريبة مستردة',
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
          // الجزء اللي العميل ماكانش دفعه بيتسوّى على حسابه، فالكاشير
          // يعرف قبل ما يأكد إنه هيدي كام كاش بالظبط.
          if (returns.settledOnAccount > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            ReturnsSummaryRow(
              label: 'بيتسوّى على حساب العميل',
              value: Fmt.money(returns.settledOnAccount),
            ),
            const SizedBox(height: AppSpacing.sm),
            ReturnsSummaryRow(
              label: returns.refundMethod == 'cash'
                  ? 'كاش من الدرج'
                  : 'على حساب العميل',
              value: Fmt.money(
                returns.refundMethod == 'cash'
                    ? returns.cashRefund
                    : returns.refundTotal - returns.settledOnAccount,
              ),
            ),
          ],
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
