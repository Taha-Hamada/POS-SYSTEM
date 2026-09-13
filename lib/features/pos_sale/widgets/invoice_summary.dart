import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/cart_controller.dart';
import 'cart_actions.dart';
import 'invoice_summary_row.dart';
import 'invoice_total_row.dart';

/// ملخص الفاتورة أسفل السلة: المجاميع + الإجمالي + الأزرار.
class InvoiceSummary extends StatelessWidget {
  const InvoiceSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cart = context.watch<CartController>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InvoiceSummaryRow(
            label: 'المجموع الفرعي',
            value: Fmt.money(cart.subtotal),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          InvoiceSummaryRow(
            label: 'الخصم${cart.discount.shortLabel}',
            value: cart.effectiveDiscount > 0
                ? '− ${Fmt.money(cart.effectiveDiscount)}'
                : Fmt.money(0),
            valueColor:
                cart.effectiveDiscount > 0 ? AppColors.success : null,
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          InvoiceSummaryRow(
            label: 'الضريبة (${(cart.taxRate * 100).toStringAsFixed(0)}%)',
            value: Fmt.money(cart.tax),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
            child: Divider(height: 1),
          ),
          InvoiceTotalRow(total: cart.total),
          const SizedBox(height: AppSpacing.xl),
          const CartActions(),
        ],
      ),
    );
  }
}
