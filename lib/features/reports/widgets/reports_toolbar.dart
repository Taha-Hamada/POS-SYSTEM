import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_dropdown.dart';
import '../../dashboard/models/dashboard_data.dart';
import '../../../theme/app_theme.dart';
import '../controllers/reports_controller.dart';
import '../models/report_period.dart';
import 'report_period_chip.dart';

/// شريط فلاتر التقارير: الفترة والفرع.
class ReportsToolbar extends StatelessWidget {
  const ReportsToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportsController reports = context.watch<ReportsController>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(radius: AppRadius.md),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.filter_alt_outlined,
            size: 17,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('الفترة', style: AppText.label.copyWith(fontSize: 12.5)),
          const SizedBox(width: AppSpacing.md),
          for (final ReportPeriod p in ReportPeriod.values) ...<Widget>[
            ReportPeriodChip(
              label: p.label,
              selected: reports.period == p,
              onTap: () => reports.setPeriod(p),
            ),
            const SizedBox(width: 4),
          ],
          const Spacer(),
          AppDropdown<String?>(
            value: reports.branchId,
            width: 220,
            height: 40,
            icon: Icons.store_outlined,
            onChanged: reports.setBranch,
            items: <AppDropdownItem<String?>>[
              const AppDropdownItem<String?>(
                value: null,
                label: 'كل الفروع',
                icon: Icons.apps_rounded,
              ),
              for (final BranchStats b in reports.branches)
                AppDropdownItem<String?>(
                  value: b.id,
                  label: b.name,
                  icon: Icons.store_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
