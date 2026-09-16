import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/history_period.dart';
import '../../../core/models/store_settings.dart';
import '../../../core/printing/print_job.dart';
import '../printing/receipt_printer.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/invoices_history_controller.dart';
import '../data/invoices_repository.dart';
import '../models/invoice_record.dart';

/// سجل الفواتير: الإجماليات والجدول والتفاصيل وإلغاء الفاتورة.
class InvoicesHistoryScreen extends StatelessWidget {
  const InvoicesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InvoicesHistoryController>(
      create: (_) => InvoicesHistoryController(
        InvoicesRepository(context.read<ApiClient>()),
      )..load(),
      child: Builder(
        builder: (BuildContext context) {
          final InvoicesHistoryController history = context
              .watch<InvoicesHistoryController>();

          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const ScreenHeader(
                  title: 'سجل الفواتير',
                  subtitle: 'كل فواتير البيع بحالتها، مع التفاصيل والإلغاء',
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatCard(
                        title: 'عدد الفواتير',
                        value: Fmt.count(history.summary.count),
                        icon: Icons.receipt_long_outlined,
                        iconColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: StatCard(
                        title: 'إجمالي المبيعات',
                        value: Fmt.moneyRounded(history.summary.total),
                        icon: Icons.payments_outlined,
                        iconColor: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: StatCard(
                        title: 'متوسط الفاتورة',
                        value: Fmt.money(history.average),
                        icon: Icons.functions_rounded,
                        iconColor: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: StatCard(
                        title: 'المرتجع منها',
                        value: Fmt.moneyRounded(history.summary.returned),
                        icon: Icons.assignment_return_outlined,
                        iconColor: AppColors.danger,
                        higherIsBetter: false,
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
                    const SizedBox(width: AppSpacing.md),
                    DropdownButton<String?>(
                      value: history.status,
                      underline: const SizedBox.shrink(),
                      hint: const Text('كل الحالات'),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          child: Text('كل الحالات'),
                        ),
                        for (final String s
                            in InvoicesHistoryController.statuses)
                          DropdownMenuItem<String?>(
                            value: s,
                            child: Text(invoiceStatusLabel(s)),
                          ),
                      ],
                      onChanged: history.setStatus,
                    ),
                    const Spacer(),
                    SearchField(
                      controller: history.searchController,
                      hint: 'رقم الفاتورة…',
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
    AppTableColumn('رقم الفاتورة', size: ColumnSize.M),
    AppTableColumn('العميل', size: ColumnSize.M),
    AppTableColumn('الكاشير والفرع', size: ColumnSize.M),
    AppTableColumn('الدفع', size: ColumnSize.S),
    AppTableColumn('الحالة', size: ColumnSize.S),
    AppTableColumn('التاريخ', size: ColumnSize.M),
    AppTableColumn('الإجمالي', size: ColumnSize.S, numeric: true),
  ];

  static StatusTone toneOf(String status) => switch (status) {
    'completed' => StatusTone.success,
    'partially_returned' => StatusTone.warning,
    'returned' => StatusTone.info,
    'voided' => StatusTone.danger,
    _ => StatusTone.neutral,
  };

  Widget _table(BuildContext context, InvoicesHistoryController history) {
    if (history.isFirstLoad) {
      return const LoadingView(message: 'بنجيب الفواتير…');
    }

    if (history.hasFailed && history.rows.isEmpty) {
      return ErrorView(message: history.errorMessage!, onRetry: history.retry);
    }

    return AppDataTable(
      minWidth: 1000,
      rowHeight: 60,
      emptyMessage: 'مفيش فواتير في الفترة دي',
      emptyIcon: Icons.receipt_long_outlined,
      columns: _columns,
      rows: <AppTableRow>[
        for (final InvoiceRecord r in history.rows)
          AppTableRow(
            onTap: () => _showDetails(context, history, r),
            cells: <Widget>[
              Text(r.number, style: AppText.bodyMedium),
              Text(r.customerName ?? 'عميل عابر', style: AppText.body),
              TableCells.twoLine(r.cashierName, r.branchName),
              Text(r.paymentsLabel, style: AppText.body),
              StatusBadge(
                label: r.statusLabel,
                tone: toneOf(r.status),
                compact: true,
              ),
              TableCells.twoLine(Fmt.date(r.createdAt), Fmt.time(r.createdAt)),
              TableCells.amount(
                r.total,
                color: r.isVoided ? AppColors.textMuted : null,
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _showDetails(
    BuildContext context,
    InvoicesHistoryController history,
    InvoiceRecord record,
  ) {
    final bool canVoid = context.read<SessionController>().can('invoice:void');
    final StoreSettings store = storeSettingsOf(context);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _InvoiceDetailsDialog(
        record: record,
        details: history.details(record),
        onPrint: () => printInvoiceReceipt(
          dialogContext,
          invoiceId: record.id,
          store: store,
        ),
        onVoid: canVoid && record.canVoid
            ? () async {
                final String? reason = await _askVoidReason(dialogContext);
                if (reason == null || !dialogContext.mounted) return;

                final ApiException? error = await history.voidInvoice(
                  record,
                  reason,
                );
                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;

                showAppSnackBar(
                  context,
                  error?.message ?? 'اتلغت الفاتورة ${record.number}',
                  isError: error != null,
                );
              }
            : null,
      ),
    );
  }

  Future<String?> _askVoidReason(BuildContext context) => showDialog<String>(
    context: context,
    builder: (_) => const _VoidReasonDialog(),
  );
}

/// بيطلب سبب الإلغاء. الحوار ماسك الكنترولر بتاعه عشان مايتقفلش
/// والنص لسه معروض في أنيميشن القفل.
class _VoidReasonDialog extends StatefulWidget {
  const _VoidReasonDialog();

  @override
  State<_VoidReasonDialog> createState() => _VoidReasonDialogState();
}

class _VoidReasonDialogState extends State<_VoidReasonDialog> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool valid = _reason.text.trim().length >= 3;

    return AlertDialog(
      title: const Text('إلغاء الفاتورة'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'الأصناف هترجع للمخزون، ولو الفاتورة على عميل حسابه '
              'هيتعدّل. الإلغاء مينفعش يترجع فيه.',
              style: AppText.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _reason,
              autofocus: true,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'سبب الإلغاء'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('رجوع'),
        ),
        SecondaryButton(
          label: 'تأكيد الإلغاء',
          tone: SecondaryButtonTone.danger,
          size: AppButtonSize.small,
          onPressed: valid
              ? () => Navigator.of(context).pop(_reason.text.trim())
              : null,
        ),
      ],
    );
  }
}

class _InvoiceDetailsDialog extends StatefulWidget {
  const _InvoiceDetailsDialog({
    required this.record,
    required this.details,
    required this.onPrint,
    this.onVoid,
  });

  final InvoiceRecord record;
  final Future<InvoiceRecord> details;

  /// إعادة طباعة الإيصال من نسخة السيرفر.
  final Future<bool> Function() onPrint;

  /// null لو المستخدم مالوش صلاحية أو الفاتورة مينفعش تتلغى.
  final Future<void> Function()? onVoid;

  @override
  State<_InvoiceDetailsDialog> createState() => _InvoiceDetailsDialogState();
}

class _InvoiceDetailsDialogState extends State<_InvoiceDetailsDialog> {
  bool _voiding = false;

  Future<void> _void() async {
    setState(() => _voiding = true);
    await widget.onVoid!();
    if (mounted) setState(() => _voiding = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('فاتورة ${widget.record.number}'),
      content: SizedBox(
        width: 560,
        child: FutureBuilder<InvoiceRecord>(
          future: widget.details,
          builder: (BuildContext context, AsyncSnapshot<InvoiceRecord> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snap.hasError) {
              final Object? error = snap.error;
              return Text(
                error is ApiException ? error.message : 'مقدرناش نجيب التفاصيل',
                style: const TextStyle(color: AppColors.danger),
              );
            }

            return _body(snap.data!);
          },
        ),
      ),
      actions: <Widget>[
        SecondaryButton(
          label: 'طباعة الإيصال',
          icon: Icons.print_outlined,
          size: AppButtonSize.small,
          onPressed: widget.onPrint,
        ),
        if (widget.onVoid != null)
          SecondaryButton(
            label: _voiding ? 'بيتلغي…' : 'إلغاء الفاتورة',
            icon: Icons.block_rounded,
            tone: SecondaryButtonTone.danger,
            size: AppButtonSize.small,
            onPressed: _voiding ? null : _void,
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Widget _body(InvoiceRecord r) {
    Widget row(String label, double value, {Color? color, bool bold = false}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: <Widget>[
              Text(label, style: bold ? AppText.bodyMedium : AppText.body),
              const Spacer(),
              Text(
                Fmt.money(value),
                style: (bold ? AppText.amountMd : AppText.amountSm).copyWith(
                  color: color,
                ),
              ),
            ],
          ),
        );

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '${r.statusLabel} • ${r.customerName ?? 'عميل عابر'} • '
            '${r.cashierName} • ${Fmt.dateTime(r.createdAt)}',
            style: AppText.caption,
          ),
          if (r.isVoided) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'اتلغت${r.voidedAt == null ? '' : ' ${Fmt.dateTime(r.voidedAt!)}'}'
              ' — ${r.voidReason}',
              style: AppText.caption.copyWith(color: AppColors.danger),
            ),
          ],
          const Divider(height: AppSpacing.xl),
          for (final InvoiceRecordLine line in r.lines)
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
                          <String>[
                            '${Fmt.trimDecimals(line.quantity)} × '
                                '${Fmt.money(line.unitPrice)}',
                            if (line.promotionName.isNotEmpty)
                              line.promotionName,
                            if (line.returnedQuantity > 0)
                              'مرتجع ${Fmt.trimDecimals(line.returnedQuantity)}',
                          ].join(' • '),
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(Fmt.money(line.lineTotal), style: AppText.amountSm),
                ],
              ),
            ),
          const Divider(height: AppSpacing.xl),
          row('الإجمالي قبل الخصم', r.subtotal),
          if (r.discountTotal > 0)
            row('الخصومات', -r.discountTotal, color: AppColors.success),
          row('الضريبة', r.taxAmount),
          row('الإجمالي', r.total, bold: true),
          const SizedBox(height: AppSpacing.sm),
          for (final InvoicePayment p in r.payments)
            row('مدفوع ${p.methodLabel}', p.amount),
          if (r.changeDue > 0) row('الباقي للعميل', r.changeDue),
          if (r.returnedTotal > 0)
            row('المرتجع', r.returnedTotal, color: AppColors.danger),
        ],
      ),
    );
  }
}
