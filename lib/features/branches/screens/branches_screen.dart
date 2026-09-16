import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/branch.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../../employees_permissions/data/employees_repository.dart';
import '../controllers/branches_controller.dart';
import '../data/branch_management_repository.dart';
import '../models/branch_stats.dart';
import '../widgets/branches_grid.dart';
import '../widgets/branches_section_title.dart';
import '../widgets/branches_stat_cards.dart';
import 'add_branch_dialog.dart';

/// شاشة الفروع — بتجمّع البطاقات الإحصائية وشبكة الفروع بس.
class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  Future<void> _openForm(BuildContext context, {Branch? existing}) async {
    final BranchesController branches = context.read<BranchesController>();

    final bool? saved = await showAddBranchDialog(
      context,
      initial: existing,
      managers: branches.managers,
      onSubmit: (BranchInput input) => branches.save(input, existing: existing),
    );

    if (saved != true || !context.mounted) return;

    showAppSnackBar(
      context,
      existing == null ? 'اتضاف الفرع الجديد' : 'اتحفظت بيانات الفرع',
      width: 460,
    );
  }

  Future<void> _toggleOpen(BuildContext context, Branch branch) async {
    final String? error = await context.read<BranchesController>().setOpen(
      branch,
      isOpen: !branch.isOpen,
    );
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      error ??
          (branch.isOpen ? 'اتقفل «${branch.name}»' : 'اتفتح «${branch.name}»'),
      isError: error != null,
      width: 460,
    );
  }

  Future<void> _deactivate(BuildContext context, Branch branch) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('تعطيل الفرع'),
        content: Text(
          '«${branch.name}» هيختفي من كل الشاشات والفلاتر، '
          'وفواتيره القديمة هتفضل موجودة في التقارير.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تعطيل'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final String? error = await context.read<BranchesController>().deactivate(
      branch,
    );
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      error ?? 'اتعطّل «${branch.name}»',
      isError: error != null,
      width: 460,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ApiClient api = context.read<ApiClient>();
    final SessionController session = context.read<SessionController>();

    final bool canManage = session.can('branch:manage');
    final bool canToggle = session.can('branch:view');

    return ChangeNotifierProvider<BranchesController>(
      create: (_) => BranchesController(
        BranchManagementRepository(api),
        // اختيار مسؤول الفرع محتاج قايمة الموظفين.
        canManage && session.can('user:view') ? EmployeesRepository(api) : null,
      )..load(),
      child: Builder(
        builder: (BuildContext context) {
          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'الفروع',
                  subtitle: 'إدارة فروع المتجر ومتابعة أدائها اليومي',
                  actions: <Widget>[
                    if (canManage)
                      PrimaryButton(
                        label: 'إضافة فرع جديد',
                        icon: Icons.add_business_outlined,
                        onPressed: () => _openForm(context),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const BranchesStatCards(),
                const SizedBox(height: AppSpacing.xl),
                const BranchesSectionTitle(),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: BranchesGrid(
                    onAddBranch: canManage ? () => _openForm(context) : null,
                    onEdit: canManage
                        ? (BranchStats s) =>
                              _openForm(context, existing: s.branch)
                        : null,
                    onToggleOpen: canToggle
                        ? (BranchStats s) => _toggleOpen(context, s.branch)
                        : null,
                    onDeactivate: canManage
                        ? (BranchStats s) => _deactivate(context, s.branch)
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
