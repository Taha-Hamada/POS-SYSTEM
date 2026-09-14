import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';
import '../models/returnable_invoice.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../models/return_accent.dart';

/// رأس بطاقة الفاتورة: رقمها وحالتها وبيانات العميل والإجمالي.
class ReturnInvoiceHeader extends StatelessWidget {
  const ReturnInvoiceHeader({super.key, required this.invoice});

  final ReturnableInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kReturnAccent.withValues(alpha: 0.10),
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 22,
              color: kReturnAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(invoice.number, style: AppText.sectionTitle),
                    const SizedBox(width: AppSpacing.sm),
                    // خارج مهلة الإرجاع بيتعلّم عشان الكاشير ياخد باله.
                    StatusBadge(
                      label: invoice.isWithinWindow
                          ? 'جوه المهلة'
                          : 'خارج مهلة الإرجاع',
                      tone: invoice.isWithinWindow
                          ? StatusTone.success
                          : StatusTone.warning,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${invoice.customerName ?? 'عميل عابر'} • '
                  '${Fmt.date(invoice.createdAt)} • '
                  'من ${Fmt.count(invoice.ageDays)} يوم',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'إجمالي الفاتورة',
                style: AppText.label.copyWith(fontSize: 11.5),
              ),
              const SizedBox(height: 2),
              Text(Fmt.money(invoice.total), style: AppText.amountLg),
            ],
          ),
        ],
      ),
    );
  }
}
