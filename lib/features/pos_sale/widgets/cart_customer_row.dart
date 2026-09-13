import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/models/customer.dart';
import '../../../theme/app_theme.dart';
import '../controllers/cart_controller.dart';
import '../controllers/sales_session_controller.dart';
import 'customer_picker_dialog.dart';

/// صف العميل المختار أعلى السلة مع زر التغيير.
class CartCustomerRow extends StatelessWidget {
  const CartCustomerRow({super.key});

  Future<void> _pickCustomer(BuildContext context) async {
    final CartController cart = context.read<CartController>();
    final Customer? picked = await showCustomerPicker(
      context,
      session: context.read<SalesSessionController>(),
    );
    if (picked != null) cart.setCustomer(picked);
  }

  @override
  Widget build(BuildContext context) {
    final Customer customer = context.watch<CartController>().customer;
    final bool isWalkIn = customer.isWalkIn;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isWalkIn
                    ? AppColors.textMuted.withValues(alpha: 0.15)
                    : AppColors.accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: isWalkIn
                  ? const Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    )
                  : Text(
                      customer.initials,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyMedium.copyWith(fontSize: 13.5),
                  ),
                  Text(
                    isWalkIn
                        ? 'بدون حساب عميل'
                        : '${customer.phone} • ${customer.tierLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SecondaryButton(
              label: 'تغيير',
              size: AppButtonSize.small,
              tone: SecondaryButtonTone.accent,
              onPressed: () => _pickCustomer(context),
            ),
          ],
        ),
      ),
    );
  }
}
