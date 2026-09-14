import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/auth_user.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/reports_controller.dart';
import '../data/reports_repository.dart';
import '../models/report_period.dart';
import '../models/report_type.dart';
import '../widgets/report_content.dart';
import '../widgets/reports_list.dart';
import '../widgets/reports_toolbar.dart';

/// شاشة التقارير — بتجمّع شريط الفلاتر وقائمة التقارير والمحتوى بس.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  /// الكنترولر محتاج vsync عشان أنيميشن الـFade عند تبديل التقرير.
  late final ReportsController _reports;

  @override
  void initState() {
    super.initState();

    final AuthUser? user = context.read<SessionController>().user;

    _reports = ReportsController(
      ReportsRepository(context.read<ApiClient>()),
      vsync: this,
      // المدير بيشوف كل الفروع، وغيره بيتقفل على فرعه.
      lockedBranchId: user != null && user.isAdmin ? null : user?.branchId,
    )..load();
  }

  @override
  void dispose() {
    _reports.dispose();
    super.dispose();
  }

  void _export(String format) {
    showPlainSnackBar(
      context,
      'جارٍ تصدير «${_reports.type.label}» بصيغة $format '
      'عن ${_reports.period.label} (تجريبي)',
      width: 520,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReportsController>.value(
      value: _reports,
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ScreenHeader(
              title: 'التقارير',
              subtitle: 'تحليلات تفصيلية قابلة للتصدير عن أداء المتجر',
              actions: <Widget>[
                SecondaryButton(
                  label: 'تحديث',
                  icon: Icons.refresh_rounded,
                  onPressed: _reports.refresh,
                ),
                SecondaryButton(
                  label: 'تصدير Excel',
                  icon: Icons.table_view_outlined,
                  tone: SecondaryButtonTone.success,
                  onPressed: () => _export('Excel'),
                ),
                PrimaryButton(
                  label: 'تصدير PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: () => _export('PDF'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const ReportsToolbar(),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // قائمة التقارير (يمين في RTL)
                  const SizedBox(width: 264, child: ReportsList()),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Consumer<ReportsController>(
                      builder: (_, ReportsController reports, _) {
                        if (reports.isFirstLoad) {
                          return const LoadingView(message: 'بنحسب التقرير…');
                        }

                        if (reports.hasFailed) {
                          return ErrorView(
                            message: reports.errorMessage!,
                            onRetry: reports.retry,
                          );
                        }

                        return const ReportContent();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
