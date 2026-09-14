import 'package:flutter/material.dart';

import '../../../core/widgets/account_timeline.dart';
import 'package:provider/provider.dart';

import '../../../core/models/customer.dart';
import '../controllers/customer_profile_controller.dart';
import '../models/customer_entries.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import 'customer_balance_box.dart';

/// التبويب التاني: كشف حساب العميل.
class CustomerLedgerTab extends StatelessWidget {
  const CustomerLedgerTab({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final List<LedgerEntry> entries =
        context.watch<CustomerProfileController>().ledger;

    return Container(
      decoration: AppDecorations.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('كشف الحساب', style: AppText.sectionTitle),
                    const SizedBox(height: 2),
                    Text(
                      '${Fmt.count(entries.length)} حركة مالية',
                      style: AppText.caption,
                    ),
                  ],
                ),
                const Spacer(),
                CustomerBalanceBox(balance: customer.balance),
              ],
            ),
          ),
          Expanded(child: AccountTimeline(entries: entries)),
        ],
      ),
    );
  }
}
