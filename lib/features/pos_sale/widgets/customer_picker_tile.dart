import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';
import '../../../core/models/customer.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// صف عميل داخل حوار اختيار العميل.
class CustomerPickerTile extends StatelessWidget {
  const CustomerPickerTile({
    super.key,
    required this.customer,
    required this.onTap,
  });

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Customer c = customer;

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      hoverColor: AppColors.surfaceAlt,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.accent.withValues(alpha: 0.12),
        child: Text(
          c.initials,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ),
      title: Text(
        c.name,
        style: AppText.bodyMedium.copyWith(fontSize: 14),
      ),
      subtitle: Text(
        c.phone,
        style: AppText.caption.copyWith(fontSize: 11.5),
      ),
      trailing: c.balance < 0
          ? StatusBadge(
              label: 'آجل ${Fmt.moneyRounded(c.balance.abs())}',
              tone: StatusTone.warning,
              compact: true,
              showDot: false,
            )
          : StatusBadge(
              label: c.tierLabel,
              tone: StatusTone.neutral,
              compact: true,
              showDot: false,
            ),
    );
  }
}
