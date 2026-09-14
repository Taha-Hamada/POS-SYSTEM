import 'package:flutter/material.dart';

import '../models/ledger_entry.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Timeline لحركات كشف الحساب — كل حركة بأيقونة تدل على نوعها.
class AccountTimeline extends StatelessWidget {
  const AccountTimeline({
    super.key,
    required this.entries,
    this.debitLabel = 'عليه',
    this.creditLabel = 'سداد',
    this.emptyMessage = 'لا توجد حركات مالية مسجّلة',
  });

  final List<LedgerEntry> entries;
  final String debitLabel;
  final String creditLabel;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 28,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(emptyMessage, style: AppText.body),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: entries.length,
      itemBuilder: (BuildContext context, int i) => _TimelineTile(
        entry: entries[i],
        isFirst: i == 0,
        isLast: i == entries.length - 1,
        debitLabel: debitLabel,
        creditLabel: creditLabel,
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.debitLabel,
    required this.creditLabel,
  });

  final LedgerEntry entry;
  final bool isFirst;
  final bool isLast;
  final String debitLabel;
  final String creditLabel;

  @override
  Widget build(BuildContext context) {
    final bool debit = entry.isDebit;
    final Color color = debit ? AppColors.warning : AppColors.success;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // الخط والأيقونة
          SizedBox(
            width: 44,
            child: Column(
              children: <Widget>[
                Container(
                  width: 2,
                  height: 10,
                  color: isFirst ? Colors.transparent : AppColors.border,
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(entry.icon, size: 17, color: color),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppColors.border,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // المحتوى
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  entry.typeLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.cardTitle.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  debit ? debitLabel : creditLabel,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            entry.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                Fmt.date(entry.date),
                                style: AppText.caption.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '${debit ? '+' : '−'} ${Fmt.money(entry.amount.abs())}',
                          style: AppText.amountMd.copyWith(color: color),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'الرصيد: ${Fmt.money(entry.balanceAfter)}',
                          style: AppText.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
