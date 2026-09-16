import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/stocktake_controller.dart';
import 'stocktake_approve_dialog.dart';

/// الشريط السفلي: صافي فرق القيمة وزر الاعتماد.
class StocktakeFooter extends StatelessWidget {
  const StocktakeFooter({super.key});

  Future<void> _approve(BuildContext context) async {
    final StocktakeController stocktake = context.read<StocktakeController>();

    final bool? confirmed = await showStocktakeApproveDialog(
      context,
      stocktake,
    );
    if (confirmed != true || !context.mounted) return;

    // الصفوف المعدودة والمطابقة مالهاش حركة، فالجرد بيتقفل من غير طلب.
    if (stocktake.pendingLines.isEmpty) {
      showAppSnackBar(context, 'الجرد مطابق — مفيش فروقات تترحّل');
      context.go('/inventory');
      return;
    }

    final StocktakeResult result = await stocktake.submit();
    if (!context.mounted) return;

    if (result.failed > 0) {
      // الأصناف اللي اتعمدت اختفى فرقها بعد إعادة التحميل، والفاشلة فاضلة
      // على الشاشة عشان يعيد محاولتها.
      showAppSnackBar(
        context,
        'اترحّل ${Fmt.count(result.applied)} صنف، وفشل '
        '${Fmt.count(result.failed)} — راجعهم وجرّب تاني',
        isError: true,
        width: 480,
      );
      return;
    }

    showAppSnackBar(
      context,
      'اتعمد الجرد واترحّلت فروقات ${Fmt.count(result.applied)} صنف',
    );
    context.go('/inventory');
  }

  @override
  Widget build(BuildContext context) {
    final StocktakeController stocktake = context.watch<StocktakeController>();
    final double netValue = stocktake.netValue;
    final bool hasCounted = stocktake.hasCounted;
    final bool busy = stocktake.isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'صافي فرق القيمة',
                style: AppText.label.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                Fmt.money(netValue),
                style: AppText.amountHero.copyWith(
                  fontSize: 26,
                  color: netValue < 0
                      ? AppColors.danger
                      : netValue > 0
                      ? AppColors.success
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xxl),
          Expanded(
            child: Text(
              hasCounted
                  ? 'تم جرد ${Fmt.count(stocktake.countedCount)} صنف من '
                        '${Fmt.count(stocktake.lines.length)}'
                  : 'ابدأ بإدخال الكميات الفعلية للأصناف',
              style: AppText.caption,
            ),
          ),
          PrimaryButton(
            label: busy ? 'بيترحّل…' : 'اعتماد الجرد',
            icon: Icons.fact_check_outlined,
            size: AppButtonSize.large,
            onPressed: hasCounted && !busy ? () => _approve(context) : null,
          ),
        ],
      ),
    );
  }
}
