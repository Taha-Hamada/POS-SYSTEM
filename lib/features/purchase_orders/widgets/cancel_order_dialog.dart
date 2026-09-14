import 'package:flutter/material.dart';

import '../../../core/models/purchase_order.dart';
import '../../../core/widgets/app_form_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// بيسأل عن سبب إلغاء أمر الشراء ويرجّعه، أو `null` لو اتلغى الحوار.
///
/// السيرفر بيطلب سبب من تلات حروف على الأقل.
Future<String?> showCancelOrderDialog(
  BuildContext context,
  PurchaseOrder order,
) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => _CancelOrderDialog(order: order),
  );
}

class _CancelOrderDialog extends StatefulWidget {
  const _CancelOrderDialog({required this.order});

  final PurchaseOrder order;

  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  final TextEditingController _reason = TextEditingController();

  bool get _canSubmit => _reason.text.trim().length >= 3;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PurchaseOrder o = widget.order;

    return Dialog(
      child: SizedBox(
        width: 460,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('إلغاء الأمر ${o.number}', style: AppText.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${o.supplierName} — ${Fmt.money(o.total)}',
                style: AppText.caption,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppFormField(
                label: 'سبب الإلغاء',
                controller: _reason,
                hint: 'مثال: المورد اعتذر عن التوريد',
                required: true,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SecondaryButton(
                      label: 'رجوع',
                      expanded: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'إلغاء الأمر',
                      icon: Icons.close_rounded,
                      color: AppColors.danger,
                      expanded: true,
                      onPressed: _canSubmit
                          ? () => Navigator.of(context).pop(_reason.text.trim())
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
