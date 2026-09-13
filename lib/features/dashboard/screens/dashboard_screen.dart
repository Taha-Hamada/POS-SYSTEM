import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/auth_user.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/staggered_reveal.dart';
import '../../../theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';
import '../data/reports_repository.dart';
import '../widgets/dashboard_charts_row.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_stats_row.dart';
import '../widgets/dashboard_tables_row.dart';

/// لوحة التحكم — بتجمّع الهيدر والبطاقات والرسوم والجداول بس.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final DashboardController _dashboard;

  @override
  void initState() {
    super.initState();

    final AuthUser? user = context.read<SessionController>().user;

    _dashboard = DashboardController(
      ReportsRepository(context.read<ApiClient>()),
      vsync: this,
      // المدير بيشوف كل الفروع، وغيره بيتقفل على فرعه.
      lockedBranchId: user != null && user.isAdmin ? null : user?.branchId,
    )..load();
  }

  @override
  void dispose() {
    _dashboard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardController>.value(
      value: _dashboard,
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final DashboardController dashboard =
        context.watch<DashboardController>();

    if (dashboard.isFirstLoad) {
      return const LoadingView(message: 'بنحسب أرقام الفترة…');
    }

    if (dashboard.hasFailed) {
      return Padding(
        padding: AppSpacing.page,
        child: ErrorView(
          message: dashboard.errorMessage!,
          onRetry: dashboard.retry,
        ),
      );
    }

    return Padding(
      padding: AppSpacing.page,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StaggeredReveal(
              controller: dashboard.entryController,
              index: 0,
              child: const DashboardHeader(),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (dashboard.isEmpty)
              const _NoSalesYet()
            else ...<Widget>[
              const DashboardStatsRow(),
              const SizedBox(height: AppSpacing.xl),
              const DashboardChartsRow(),
              const SizedBox(height: AppSpacing.xl),
              const DashboardTablesRow(),
            ],
          ],
        ),
      ),
    );
  }
}

/// الفترة مفيهاش فواتير — مختلفة عن الفشل، فبنقولها صريح.
class _NoSalesYet extends StatelessWidget {
  const _NoSalesYet();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 360,
      child: EmptyView(
        title: 'مفيش مبيعات في الفترة دي',
        description: 'غيّر الفترة من فوق، أو ابدأ البيع من شاشة الكاشير.',
        icon: Icons.query_stats_outlined,
      ),
    );
  }
}
