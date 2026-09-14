import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../features/payment/models/payment_entry.dart';
import '../../../core/models/payment_method.dart';
import '../../../features/payment/models/payment_result.dart';
import '../../../features/payment/screens/payment_dialog.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/cart_controller.dart';
import '../controllers/sales_session_controller.dart';
import '../data/pos_repository.dart';
import '../models/cart_discount.dart';
import 'discount_dialog.dart';

/// أزرار أسفل السلة: تعليق الفاتورة، خصم، والدفع.
class CartActions extends StatelessWidget {
  const CartActions({super.key});

  Future<void> _holdInvoice(BuildContext context) async {
    final SalesSessionController session =
        context.read<SalesSessionController>();

    final String? error = await session.holdActive();
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      error ?? 'اتعلّقت الفاتورة واتحجز رصيدها — ترجّعها من زرار ⏸ فوق السلة',
      isError: error != null,
    );
  }

  Future<void> _applyDiscount(BuildContext context) async {
    final CartController cart = context.read<CartController>();
    final CartDiscount? discount = await showDiscountDialog(
      context,
      subtotal: cart.subtotal,
      current: cart.discount,
    );
    if (discount == null || !context.mounted) return;

    cart.setDiscount(discount);
    showAppSnackBar(
      context,
      discount.isEmpty
          ? 'تم إلغاء الخصم'
          : 'تم تطبيق خصم ${Fmt.money(cart.effectiveDiscount)}',
    );
  }

  Future<void> _pay(BuildContext context) async {
    final CartController cart = context.read<CartController>();
    final SalesSessionController session =
        context.read<SalesSessionController>();

    final PaymentResult? result = await showPaymentDialog(
      context: context,
      total: cart.total,
      itemsCount: cart.itemsCount,
      customerName: cart.customer.name,
    );
    if (result == null || !context.mounted) return;

    try {
      // السيرفر بيعيد حساب الفاتورة ويخصم المخزون، وبيرجّع رقمها الرسمي.
      final CompletedInvoice invoice = await session.checkout(
        <PaymentInput>[
          for (final PaymentEntry entry in result.entries)
            PaymentInput(method: entry.method.apiValue, amount: entry.amount),
        ],
      );

      if (!context.mounted) return;

      showAppSnackBar(
        context,
        invoice.changeDue > 0.005
            ? 'اتسجّلت الفاتورة ${invoice.number} — الباقي ${Fmt.money(invoice.changeDue)}'
            : 'اتسجّلت الفاتورة ${invoice.number}',
      );
    } on ApiException catch (exception) {
      if (!context.mounted) return;

      // السلة بتفضل زي ما هي عشان الكاشير يقدر يصلّح ويعيد المحاولة.
      showAppSnackBar(context, exception.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final CartController cart = context.watch<CartController>();
    final bool busy = context.select((SalesSessionController s) => s.isLoading);
    final bool hasItems = cart.isNotEmpty;
    final bool enabled = hasItems && !busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: SecondaryButton(
                label: 'تعليق الفاتورة',
                icon: Icons.pause_circle_outline_rounded,
                expanded: true,
                onPressed: enabled ? () => _holdInvoice(context) : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SecondaryButton(
                label: 'خصم',
                icon: Icons.local_offer_outlined,
                expanded: true,
                onPressed: enabled ? () => _applyDiscount(context) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'الدفع',
          icon: Icons.payments_rounded,
          size: AppButtonSize.hero,
          expanded: true,
          onPressed: enabled ? () => _pay(context) : null,
          trailing: hasItems
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    Fmt.money(cart.total),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
