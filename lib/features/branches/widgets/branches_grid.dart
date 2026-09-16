import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/async_state_views.dart';
import '../../../theme/app_theme.dart';
import '../controllers/branches_controller.dart';
import '../models/branch_stats.dart';
import 'add_branch_card.dart';
import 'branch_card.dart';

/// شبكة بطاقات الفروع + بطاقة الإضافة في آخرها.
class BranchesGrid extends StatelessWidget {
  const BranchesGrid({
    super.key,
    this.onAddBranch,
    this.onEdit,
    this.onToggleOpen,
    this.onDeactivate,
  });

  /// كلها null لو المستخدم مالوش صلاحية على الإجراء.
  final VoidCallback? onAddBranch;
  final ValueChanged<BranchStats>? onEdit;
  final ValueChanged<BranchStats>? onToggleOpen;
  final ValueChanged<BranchStats>? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final BranchesController branches = context.watch<BranchesController>();

    if (branches.isFirstLoad) {
      return const LoadingView(message: 'بنحمّل الفروع…');
    }

    if (branches.hasFailed && branches.rows.isEmpty) {
      return ErrorView(
        message: branches.errorMessage!,
        onRetry: branches.retry,
      );
    }

    return GridView(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 260,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
      ),
      children: <Widget>[
        for (final BranchStats s in branches.rows)
          BranchCard(
            key: ValueKey<String>(s.branch.id),
            stats: s,
            onEdit: onEdit == null ? null : () => onEdit!(s),
            onToggleOpen: onToggleOpen == null ? null : () => onToggleOpen!(s),
            onDeactivate: onDeactivate == null ? null : () => onDeactivate!(s),
          ),
        if (onAddBranch != null) AddBranchCard(onTap: onAddBranch!),
      ],
    );
  }
}
