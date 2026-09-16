import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/data/branches_repository.dart';
import '../../../core/models/branch.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/stock_alerts_controller.dart';
import '../data/stock_alerts_repository.dart';

/// شاشة تنبيهات المخزون: الأصناف الناقصة وقرب انتهاء الصلاحية.
class StockAlertsScreen extends StatelessWidget {
  const StockAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiClient api = context.read<ApiClient>();
    final SessionController session = context.read<SessionController>();

    return ChangeNotifierProvider<StockAlertsController>(
      create: (_) => StockAlertsController(
        StockAlertsRepository(api),
        BranchesRepository(api),
        branchId: session.user?.branchId,
      )..load(),
      child: Builder(
        builder: (BuildContext context) {
          final StockAlertsController alerts = context
              .watch<StockAlertsController>();

          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'تنبيهات المخزون',
                  subtitle: 'أصناف محتاجة إعادة طلب ومنتجات صلاحيتها قربت تخلص',
                  leading: BackCircleButton(
                    onTap: () => context.go('/inventory'),
                    tooltip: 'رجوع للمخزون',
                  ),
                  actions: <Widget>[
                    if (session.can('purchase:manage'))
                      SecondaryButton(
                        label: 'أمر شراء جديد',
                        icon: Icons.add_shopping_cart_rounded,
                        tone: SecondaryButtonTone.accent,
                        onPressed: () => context.go('/purchases/new'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                if (alerts.isFirstLoad)
                  const Expanded(
                    child: LoadingView(message: 'بنجمع التنبيهات…'),
                  )
                else if (alerts.hasFailed &&
                    alerts.lowStock.isEmpty &&
                    alerts.expiring.isEmpty)
                  Expanded(
                    child: ErrorView(
                      message: alerts.errorMessage!,
                      onRetry: alerts.retry,
                    ),
                  )
                else ...<Widget>[
                  const _AlertStatCards(),
                  const SizedBox(height: AppSpacing.xl),
                  const Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(child: _LowStockPanel()),
                        SizedBox(width: AppSpacing.lg),
                        Expanded(child: _ExpiringPanel()),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AlertStatCards extends StatelessWidget {
  const _AlertStatCards();

  @override
  Widget build(BuildContext context) {
    final StockAlertsController alerts = context.watch<StockAlertsController>();

    return Row(
      children: <Widget>[
        Expanded(
          child: StatCard(
            title: 'أصناف نفدت',
            value: Fmt.count(alerts.outOfStockCount),
            icon: Icons.remove_shopping_cart_outlined,
            iconColor: AppColors.danger,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'تحت حد إعادة الطلب',
            value: Fmt.count(alerts.belowMinCount),
            icon: Icons.trending_down_rounded,
            iconColor: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'صلاحيتها بتخلص خلال ${alerts.days} يوم',
            value: Fmt.count(alerts.expiringSoonCount),
            icon: Icons.event_busy_outlined,
            iconColor: AppColors.info,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: StatCard(
            title: 'منتهية الصلاحية',
            value: Fmt.count(alerts.expiredCount),
            icon: Icons.dangerous_outlined,
            iconColor: AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _LowStockPanel extends StatelessWidget {
  const _LowStockPanel();

  static const List<AppTableColumn> _columns = <AppTableColumn>[
    AppTableColumn('الصنف', size: ColumnSize.L),
    AppTableColumn('الفرع', size: ColumnSize.M),
    AppTableColumn('الرصيد / الحد', size: ColumnSize.S, numeric: true),
    AppTableColumn('الحالة', size: ColumnSize.S),
  ];

  String _qty(double v) =>
      v == v.roundToDouble() ? Fmt.count(v.toInt()) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final StockAlertsController alerts = context.watch<StockAlertsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('نواقص المخزون', style: AppText.sectionTitle),
            const Spacer(),
            AppDropdown<String?>(
              value: alerts.branchId,
              width: 200,
              icon: Icons.store_outlined,
              onChanged: alerts.setBranch,
              items: <AppDropdownItem<String?>>[
                const AppDropdownItem<String?>(value: null, label: 'كل الفروع'),
                for (final Branch b in alerts.branches)
                  AppDropdownItem<String?>(value: b.id, label: b.name),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppDataTable(
            minWidth: 520,
            rowHeight: 58,
            emptyMessage: 'مفيش أصناف تحت حد إعادة الطلب',
            emptyIcon: Icons.check_circle_outline_rounded,
            columns: _columns,
            rows: <AppTableRow>[
              for (final LowStockAlert a in alerts.lowStock)
                AppTableRow(
                  cells: <Widget>[
                    TableCells.twoLine(a.name, a.sku),
                    Text(
                      a.branchName,
                      style: AppText.body.copyWith(fontSize: 13),
                    ),
                    Text(
                      '${_qty(a.quantity)} / ${_qty(a.minStock)} ${a.unit}',
                      style: AppText.amountSm,
                    ),
                    StatusBadge(
                      label: a.isOut ? 'نفد' : 'منخفض',
                      tone: a.isOut ? StatusTone.danger : StatusTone.warning,
                      compact: true,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpiringPanel extends StatelessWidget {
  const _ExpiringPanel();

  static const List<AppTableColumn> _columns = <AppTableColumn>[
    AppTableColumn('المنتج', size: ColumnSize.L),
    AppTableColumn('تاريخ الانتهاء', size: ColumnSize.M),
    AppTableColumn('الحالة', size: ColumnSize.S),
  ];

  @override
  Widget build(BuildContext context) {
    final StockAlertsController alerts = context.watch<StockAlertsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('قرب انتهاء الصلاحية', style: AppText.sectionTitle),
            const Spacer(),
            AppDropdown<int>(
              value: alerts.days,
              width: 170,
              icon: Icons.date_range_outlined,
              onChanged: alerts.setDays,
              items: <AppDropdownItem<int>>[
                for (final int d in StockAlertsController.dayOptions)
                  AppDropdownItem<int>(value: d, label: 'خلال $d يوم'),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppDataTable(
            minWidth: 460,
            rowHeight: 58,
            emptyMessage: 'مفيش منتجات صلاحيتها قربت تخلص',
            emptyIcon: Icons.check_circle_outline_rounded,
            columns: _columns,
            rows: <AppTableRow>[
              for (final ExpiringProduct p in alerts.expiring)
                AppTableRow(
                  cells: <Widget>[
                    TableCells.twoLine(p.name, p.sku),
                    Text(Fmt.date(p.expiryDate), style: AppText.body),
                    StatusBadge(
                      label: p.isExpired
                          ? 'منتهي'
                          : p.daysLeft == 0
                          ? 'بينتهي النهاردة'
                          : 'باقي ${p.daysLeft} يوم',
                      tone: p.isExpired || p.daysLeft <= 7
                          ? StatusTone.danger
                          : StatusTone.warning,
                      compact: true,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
