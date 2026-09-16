import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/returns_history_controller.dart';
import '../data/returns_history_repository.dart';
import '../models/return_record.dart';

/// سجل المرتجعات: الإجماليات والجدول وتفاصيل كل مرتجع.
class ReturnsHistoryScreen extends StatelessWidget {
  const ReturnsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReturnsHistoryController>(
      create: (_) => ReturnsHistoryController(
        ReturnsHistoryRepository(context.read<ApiClient>()),
      )..load(),
      child: Builder(
        builder: (BuildContext context) {
          final ReturnsHistoryController history = context
              .watch<ReturnsHistoryController>();

          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'سجل المرتجعات',
                  subtitle: 'كل المرتجعات المسجّلة بقيمتها وطريقة ردّها',
                  leading: BackCircleButton(
                    onTap: () => context.go('/returns'),
                    tooltip: 'رجوع للمرتجعات',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatCard(
                        title: 'عدد المرتجعات',
                        value: Fmt.count(history.summary.count),
                        icon: Icons.assignment_return_outlined,
                        iconColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: StatCard(
                        title: 'إجمالي المرتجع',
                        value: Fmt.moneyRounded(history.summary.total),
                        icon: Icons.payments_outlined,
                        iconColor: AppColors.danger,
                        higherIsBetter: false,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: StatCard(
                        title: 'متوسط المرتجع',
                        value: Fmt.money(history.average),
                        icon: Icons.functions_rounded,
                        iconColor: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: <Widget>[
                    Text('المرتجعات', style: AppText.sectionTitle),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '(${Fmt.count(history.totalCount)})',
                      style: AppText.caption,
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    for (final ReturnsPeriod p
                        in ReturnsPeriod.values) ...<Widget>[
                      ChoiceChip(
                        label: Text(p.label),
                        selected: history.period == p,
                        onSelected: (_) => history.setPeriod(p),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    const Spacer(),
                    SearchField(
                      controller: history.searchController,
                      hint: 'رقم المرتجع…',
                      onChanged: history.setQuery,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(child: _table(context, history)),
              ],
            ),
          );
        },
      ),
    );
  }

  static const List<AppTableColumn> _columns = <AppTableColumn>[
    AppTableColumn('رقم المرتجع', size: ColumnSize.M),
    AppTableColumn('الفاتورة', size: ColumnSize.M),
    AppTableColumn('العميل', size: ColumnSize.M),
    AppTableColumn('الكاشير والفرع', size: ColumnSize.M),
    AppTableColumn('طريقة الرد', size: ColumnSize.S),
    AppTableColumn('التاريخ', size: ColumnSize.M),
    AppTableColumn('المبلغ', size: ColumnSize.S, numeric: true),
  ];

  Widget _table(BuildContext context, ReturnsHistoryController history) {
    if (history.isFirstLoad) {
      return const LoadingView(message: 'بنجيب المرتجعات…');
    }

    if (history.hasFailed && history.rows.isEmpty) {
      return ErrorView(message: history.errorMessage!, onRetry: history.retry);
    }

    return AppDataTable(
      minWidth: 1000,
      rowHeight: 60,
      emptyMessage: 'مفيش مرتجعات في الفترة دي',
      emptyIcon: Icons.assignment_return_outlined,
      columns: _columns,
      rows: <AppTableRow>[
        for (final ReturnRecord r in history.rows)
          AppTableRow(
            onTap: () => _showDetails(context, history, r),
            cells: <Widget>[
              Text(r.number, style: AppText.bodyMedium),
              Text(r.invoiceNumber, style: AppText.body),
              Text(r.customerName ?? 'عميل عابر', style: AppText.body),
              TableCells.twoLine(r.cashierName, r.branchName),
              StatusBadge(
                label: r.refundMethodLabel,
                tone: r.refundMethod == 'credit'
                    ? StatusTone.info
                    : StatusTone.neutral,
                compact: true,
              ),
              TableCells.twoLine(Fmt.date(r.createdAt), Fmt.time(r.createdAt)),
              TableCells.amount(r.total),
            ],
          ),
      ],
    );
  }

  Future<void> _showDetails(
    BuildContext context,
    ReturnsHistoryController history,
    ReturnRecord record,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('مرتجع ${record.number}'),
        content: SizedBox(
          width: 520,
          child: FutureBuilder<ReturnRecord>(
            future: history.details(record),
            builder: (BuildContext context, AsyncSnapshot<ReturnRecord> snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snap.hasError) {
                final Object? error = snap.error;
                return Text(
                  error is ApiException
                      ? error.message
                      : 'مقدرناش نجيب التفاصيل',
                  style: const TextStyle(color: AppColors.danger),
                );
              }

              final ReturnRecord r = snap.data!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'فاتورة ${r.invoiceNumber} • ${r.refundMethodLabel} • '
                    '${Fmt.date(r.createdAt)} ${Fmt.time(r.createdAt)}',
                    style: AppText.caption,
                  ),
                  if (r.reason.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text('السبب: ${r.reason}', style: AppText.caption),
                  ],
                  const Divider(height: AppSpacing.xl),
                  for (final ReturnRecordLine line in r.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(line.name, style: AppText.bodyMedium),
                                Text(
                                  line.restock
                                      ? 'رجع للمخزون'
                                      : 'تالف — مرجعش للمخزون',
                                  style: AppText.caption.copyWith(
                                    color: line.restock
                                        ? null
                                        : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '× ${line.quantity == line.quantity.roundToDouble() ? line.quantity.toInt() : line.quantity}',
                            style: AppText.body,
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Text(
                            Fmt.money(line.lineTotal),
                            style: AppText.amountSm,
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: AppSpacing.xl),
                  Row(
                    children: <Widget>[
                      Text(
                        'إجمالي المرتجع شامل الضريبة',
                        style: AppText.bodyMedium,
                      ),
                      const Spacer(),
                      Text(Fmt.money(r.total), style: AppText.amountMd),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
