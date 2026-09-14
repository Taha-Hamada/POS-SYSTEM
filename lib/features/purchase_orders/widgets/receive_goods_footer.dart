import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/purchase_order.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/receive_goods_controller.dart';

/// فوتر حوار الاستلام: قيمة الاستلام وأزرار التصفير والاستلام.
class ReceiveGoodsFooter extends StatelessWidget {
  const ReceiveGoodsFooter({super.key});

  Future<void> _submit(BuildContext context) async {
    final ReceiveGoodsController receive =
        context.read<ReceiveGoodsController>();

    final PurchaseOrder? updated = await receive.submit();
    if (!context.mounted) return;

    if (updated == null) {
      showPlainSnackBar(
        context,
        receive.submitError ?? 'مقدرناش نسجّل الاستلام',
        width: 460,
      );
      return;
    }

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final ReceiveGoodsController receive =
        context.watch<ReceiveGoodsController>();
    final bool isComplete = receive.isComplete;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(AppRadius.xl),
          bottomLeft: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'قيمة الاستلام الحالي',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        Fmt.money(receive.receivingValue),
                        style: AppText.amountLg,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SecondaryButton(
                label: 'تصفير',
                onPressed: receive.isLoading ? null : receive.clearAll,
              ),
              const SizedBox(width: AppSpacing.sm),
              SecondaryButton(
                label: 'استلام الكل',
                icon: Icons.done_all_rounded,
                tone: SecondaryButtonTone.accent,
                onPressed: receive.isLoading ? null : receive.receiveAll,
              ),
              const SizedBox(width: AppSpacing.md),
              PrimaryButton(
                label: receive.isLoading
                    ? 'بنسجّل…'
                    : (isComplete ? 'إتمام الاستلام' : 'تسجيل استلام جزئي'),
                icon: Icons.check_circle_outline_rounded,
                size: AppButtonSize.large,
                color: isComplete ? AppColors.success : null,
                onPressed: receive.canSubmit ? () => _submit(context) : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // المتوسط المرجح بيحمي هامش الربح من إن سعر شحنة واحدة يقلب التكلفة.
          Row(
            children: <Widget>[
              Checkbox(
                value: receive.updateCost,
                onChanged: (bool? value) =>
                    receive.setUpdateCost(value: value ?? false),
              ),
              Flexible(
                child: Text(
                  'حدّث تكلفة الأصناف بالمتوسط المرجح مع الاستلام',
                  style: AppText.caption.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
