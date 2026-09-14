import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/purchase_order.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/create_purchase_order_controller.dart';
import 'create_po_grand_total.dart';
import 'create_po_total_item.dart';

/// الشريط السفلي: الإجماليات وأزرار الحفظ والاعتماد.
///
/// مفيش ضريبة على أمر الشراء — إجماليه قيمة الأصناف زائد الشحن، والشحن
/// بيتوزّع على تكلفة الأصناف وقت الاستلام.
class CreatePoTotalsBar extends StatelessWidget {
  const CreatePoTotalsBar({super.key});

  Future<void> _save(BuildContext context, {required bool confirm}) async {
    final CreatePurchaseOrderController draft =
        context.read<CreatePurchaseOrderController>();

    final PurchaseOrder? created = await draft.submit(confirm: confirm);
    if (!context.mounted) return;

    if (created == null) {
      showPlainSnackBar(
        context,
        draft.saveError ?? 'مقدرناش نحفظ أمر الشراء',
        width: 460,
      );
      return;
    }

    showPlainSnackBar(
      context,
      confirm
          ? 'اتعمل أمر الشراء ${created.number} واتأكد بقيمة '
              '${Fmt.money(created.total)}'
          : 'اتحفظ أمر الشراء ${created.number} كمسودة',
      width: 460,
    );

    context.go('/purchases');
  }

  @override
  Widget build(BuildContext context) {
    final CreatePurchaseOrderController draft =
        context.watch<CreatePurchaseOrderController>();
    final bool ready = draft.canSubmit;

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
          // الإجماليات بتتزحلق أفقيًا لو المساحة ضاقت بدل ما تفيض
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  CreatePoTotalItem(
                    label: 'قيمة الأصناف',
                    value: Fmt.money(draft.subtotal),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  const _ShippingField(),
                  Container(
                    width: 1,
                    height: 44,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    color: AppColors.border,
                  ),
                  const CreatePoGrandTotal(),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          SecondaryButton(
            label: 'حفظ كمسودة',
            icon: Icons.save_outlined,
            size: AppButtonSize.large,
            onPressed: ready ? () => _save(context, confirm: false) : null,
          ),
          const SizedBox(width: AppSpacing.md),
          PrimaryButton(
            label: draft.isLoading ? 'بنحفظ…' : 'إنشاء واعتماد الأمر',
            icon: Icons.check_circle_outline_rounded,
            size: AppButtonSize.large,
            onPressed: ready ? () => _save(context, confirm: true) : null,
          ),
        ],
      ),
    );
  }
}

/// مصاريف الشحن — بتضاف لإجمالي الأمر وبتتوزّع على التكلفة وقت الاستلام.
class _ShippingField extends StatefulWidget {
  const _ShippingField();

  @override
  State<_ShippingField> createState() => _ShippingFieldState();
}

class _ShippingFieldState extends State<_ShippingField> {
  @override
  Widget build(BuildContext context) {
    final CreatePurchaseOrderController draft =
        context.read<CreatePurchaseOrderController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'مصاريف الشحن',
          style: AppText.label.copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 120,
          height: 34,
          child: TextField(
            controller: draft.shippingController,
            onChanged: draft.fieldChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: AppText.amountMd.copyWith(fontSize: 16),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              suffixText: Fmt.currencySymbol,
            ),
          ),
        ),
      ],
    );
  }
}
