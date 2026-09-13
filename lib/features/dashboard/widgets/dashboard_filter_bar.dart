import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_dropdown.dart';
import '../models/dashboard_data.dart';
import '../../../theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_period.dart';
import 'dashboard_period_chip.dart';

/// شريط الفلترة: شرائح الفترة + فلتر الفرع.
class DashboardFilterBar extends StatelessWidget {
  const DashboardFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController dashboard = context.watch<DashboardController>();

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: AppDecorations.card(radius: AppRadius.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final DashboardPeriod p in DashboardPeriod.values) ...<Widget>[
            DashboardPeriodChip(
              label: p.label,
              selected: dashboard.period == p,
              onTap: () => dashboard.setPeriod(p),
            ),
            const SizedBox(width: 3),
          ],
          Container(
            width: 1,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            color: AppColors.border,
          ),
          // الفروع بتتاخد من تقرير المقارنة، وهو مقصور على اللي بيشوف الفروع.
          // غير كده الفلتر بيتقفل على فرع المستخدم.
          if (dashboard.canSwitchBranch &&
              dashboard.branchesPerformance.isNotEmpty)
            AppDropdown<String?>(
              value: dashboard.branchId,
              width: 210,
              height: 38,
              icon: Icons.store_outlined,
              onChanged: dashboard.setBranch,
              items: <AppDropdownItem<String?>>[
                const AppDropdownItem<String?>(
                  value: null,
                  label: 'كل الفروع',
                  icon: Icons.apps_rounded,
                ),
                for (final BranchStats b in dashboard.branchesPerformance)
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
