import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/history_period.dart';
import '../../../core/models/shift.dart';
import '../../../core/models/store_settings.dart';
import '../../../core/printing/pdf_kit.dart';
import '../../../core/printing/print_job.dart';
import '../printing/shift_report_pdf.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/shifts_history_controller.dart';
import '../data/shift_repository.dart';

/// سجل الورديات: مين فتح وقفل، والمبيعات، وفرق الدرج.
class ShiftsHistoryScreen extends StatelessWidget {
  const ShiftsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ShiftsHistoryController>(
      create: (_) =>
          ShiftsHistoryController(ShiftRepository(context.read<ApiClient>()))
            ..load(),
      child: Builder(
        builder: (BuildContext context) {
          final ShiftsHistoryController history = context
              .watch<ShiftsHistoryController>();
          final double diff = history.netDifference;

          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const ScreenHeader(
                  title: 'سجل الورديات',
                  subtitle: 'الورديات بمبيعاتها ونتيجة تقفيل الدرج',
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatCard(
                        title: 'عدد الورديات',
                        value: Fmt.count(history.totalCount),
                        icon: Icons.schedule_rounded,
                        iconColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: StatCard(
                        title: 'مفتوحة الآن',
                        value: Fmt.count(history.openCount),
                        icon: Icons.lock_open_rounded,
                        iconColor: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: StatCard(
                        title: 'مبيعات الورديات المقفولة',
                        value: Fmt.moneyRounded(history.closedSales),
                        icon: Icons.payments_outlined,
                        iconColor: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: StatCard(
                        title: 'صافي فروقات الدرج',
                        value: Fmt.money(diff),
                        icon: Icons.balance_rounded,
                        iconColor: diff < 0
                            ? AppColors.danger
                            : AppColors.success,
                        footer: Text(
                          '${Fmt.count(history.shortCount)} وردية فيها عجز',
                          style: AppText.caption,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: <Widget>[
                    for (final HistoryPeriod p
                        in HistoryPeriod.values) ...<Widget>[
                      ChoiceChip(
                        label: Text(p.label),
                        selected: history.period == p,
                        onSelected: (_) => history.setPeriod(p),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    const Spacer(),
                    DropdownButton<String?>(
                      value: history.status,
                      underline: const SizedBox.shrink(),
                      hint: const Text('كل الورديات'),
                      items: const <DropdownMenuItem<String?>>[
                        DropdownMenuItem<String?>(child: Text('كل الورديات')),
                        DropdownMenuItem<String?>(
                          value: 'open',
                          child: Text('مفتوحة'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'closed',
                          child: Text('مقفولة'),
                        ),
                      ],
                      onChanged: history.setStatus,
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
    AppTableColumn('الوردية', size: ColumnSize.S),
    AppTableColumn('الكاشير والفرع', size: ColumnSize.M),
    AppTableColumn('الفتح', size: ColumnSize.M),
    AppTableColumn('القفل', size: ColumnSize.M),
    AppTableColumn('الحالة', size: ColumnSize.S),
    AppTableColumn('المبيعات', size: ColumnSize.S, numeric: true),
    AppTableColumn('فرق الدرج', size: ColumnSize.S, numeric: true),
  ];

  Widget _table(BuildContext context, ShiftsHistoryController history) {
    if (history.isFirstLoad) {
      return const LoadingView(message: 'بنجيب الورديات…');
    }

    if (history.hasFailed && history.rows.isEmpty) {
      return ErrorView(message: history.errorMessage!, onRetry: history.retry);
    }

    return AppDataTable(
      minWidth: 1000,
      rowHeight: 60,
      emptyMessage: 'مفيش ورديات في الفترة دي',
      emptyIcon: Icons.schedule_rounded,
      columns: _columns,
      rows: <AppTableRow>[
        for (final Shift s in history.rows)
          AppTableRow(
            onTap: () => _showDetails(context, history, s),
            cells: <Widget>[
              Text(s.number, style: AppText.bodyMedium),
              TableCells.twoLine(s.cashierName ?? '—', s.branchName ?? '—'),
              TableCells.twoLine(Fmt.date(s.openedAt), Fmt.time(s.openedAt)),
              s.closedAt == null
                  ? Text('—', style: AppText.caption)
                  : TableCells.twoLine(
                      Fmt.date(s.closedAt!),
                      Fmt.time(s.closedAt!),
                    ),
              StatusBadge(
                label: s.isOpen ? 'مفتوحة' : 'مقفولة',
                tone: s.isOpen ? StatusTone.info : StatusTone.neutral,
                compact: true,
              ),
              s.closing == null
                  ? Text('—', style: AppText.caption)
                  : TableCells.amount(s.closing!.salesTotal),
              s.closing == null
                  ? Text('—', style: AppText.caption)
                  : TableCells.amount(
                      s.closing!.difference,
                      color: _differenceColor(s.closing!),
                    ),
            ],
          ),
      ],
    );
  }

  static Color _differenceColor(ShiftClosing closing) => closing.isBalanced
      ? AppColors.textPrimary
      : closing.isShort
      ? AppColors.danger
      : AppColors.success;

  Future<void> _showDetails(
    BuildContext context,
    ShiftsHistoryController history,
    Shift shift,
  ) {
    final StoreSettings store = storeSettingsOf(context);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('وردية ${shift.number}'),
        content: SizedBox(
          width: 480,
          child: FutureBuilder<ShiftSnapshot>(
            future: history.details(shift),
            builder: (BuildContext context, AsyncSnapshot<ShiftSnapshot> snap) {
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

              return _detailsBody(snap.data!);
            },
          ),
        ),
        actions: <Widget>[
          // إعادة طباعة التقرير بأرقام السيرفر — المتجمّدة لو الوردية مقفولة.
          TextButton.icon(
            onPressed: () async {
              final ShiftSnapshot snapshot = await history.details(shift);
              if (!context.mounted) return;

              await printDocument(
                context,
                name: 'تقرير وردية ${shift.number}',
                format: PdfKit.rollFormat(store.receiptWidthMm),
                build: (format) => buildShiftReportPdf(
                  shift: snapshot.shift,
                  totals: snapshot.totals,
                  store: store,
                  format: format,
                ),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('طباعة التقرير'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _detailsBody(ShiftSnapshot snapshot) {
    final Shift s = snapshot.shift;
    final ShiftTotals t = snapshot.totals;
    final ShiftClosing? closing = s.closing;

    Widget row(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Text(label, style: AppText.body),
          const Spacer(),
          Text(value, style: AppText.amountSm.copyWith(color: color)),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '${s.cashierName ?? ''} • ${s.branchName ?? ''} • '
          'من ${Fmt.dateTime(s.openedAt)}'
          '${s.closedAt == null ? '' : ' لـ ${Fmt.time(s.closedAt!)}'}',
          style: AppText.caption,
        ),
        const Divider(height: AppSpacing.xl),
        row('الرصيد الافتتاحي', Fmt.money(s.openingBalance)),
        row('المبيعات', Fmt.money(t.salesTotal)),
        row('عدد الفواتير', Fmt.count(t.invoicesCount)),
        row('مبيعات كاش', Fmt.money(t.cashSales)),
        if (t.creditSales > 0) row('مبيعات آجل', Fmt.money(t.creditSales)),
        if (t.returnsTotal > 0)
          row('المرتجعات', Fmt.money(t.returnsTotal), color: AppColors.danger),
        if (t.cashIn > 0) row('إيداعات', Fmt.money(t.cashIn)),
        if (t.cashOut > 0) row('مسحوبات', Fmt.money(t.cashOut)),
        const Divider(height: AppSpacing.xl),
        if (closing == null)
          row('المتوقع في الدرج دلوقتي', Fmt.money(t.expectedCash))
        else ...<Widget>[
          row('المتوقع في الدرج', Fmt.money(closing.expectedCash)),
          row('المعدود فعلًا', Fmt.money(closing.countedCash)),
          row(
            closing.isBalanced
                ? 'الدرج مظبوط'
                : closing.isShort
                ? 'عجز'
                : 'زيادة',
            Fmt.money(closing.difference.abs()),
            color: _differenceColor(closing),
          ),
          if (closing.note.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text('ملاحظة: ${closing.note}', style: AppText.caption),
          ],
        ],
      ],
    );
  }
}
