import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../theme/app_theme.dart';
import '../controllers/inventory_controller.dart';
import '../data/inventory_repository.dart';
import '../widgets/inventory_filter_bar.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_stat_cards.dart';
import '../widgets/inventory_table.dart';

/// شاشة المخزون — بتجمّع الهيدر والبطاقات وشريط الفلترة والجدول بس.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? branchId = context.read<SessionController>().user?.branchId;

    // المخزون بيتحسب لفرع، والمدير مش مربوط بفرع، فبيختار واحد من الفلتر.
    if (branchId == null) {
      return const _PickBranchFirst();
    }

    return ChangeNotifierProvider<InventoryController>(
      create: (BuildContext context) => InventoryController(
        InventoryRepository(context.read<ApiClient>()),
        branchId: branchId,
      )..load(),
      child: const _InventoryBody(),
    );
  }
}

class _InventoryBody extends StatelessWidget {
  const _InventoryBody();

  @override
  Widget build(BuildContext context) {
    final InventoryController inventory = context.watch<InventoryController>();

    if (inventory.isFirstLoad) {
      return const LoadingView(message: 'بنجيب أرصدة الفرع…');
    }

    if (inventory.hasFailed) {
      return Padding(
        padding: AppSpacing.page,
        child: ErrorView(
          message: inventory.errorMessage!,
          onRetry: inventory.retry,
        ),
      );
    }

    return Padding(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const InventoryHeader(),
          const SizedBox(height: AppSpacing.xl),
          const InventoryStatCards(),
          const SizedBox(height: AppSpacing.xl),
          const InventoryFilterBar(),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: inventory.isEmpty
                ? const EmptyView(
                    title: 'مفيش أصناف مطابقة',
                    description: 'غيّر الفلتر أو ضيف منتجات للفرع ده.',
                    icon: Icons.inventory_2_outlined,
                  )
                : const InventoryTable(),
          ),
        ],
      ),
    );
  }
}

/// المدير مش مربوط بفرع، فلازم يحدد فرع قبل ما يشوف مخزونه.
class _PickBranchFirst extends StatelessWidget {
  const _PickBranchFirst();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppSpacing.page,
      child: EmptyView(
        title: 'حدد الفرع الأول',
        description:
            'حسابك مش مربوط بفرع. اربطه بفرع من شاشة الموظفين عشان تشوف مخزونه.',
        icon: Icons.store_outlined,
      ),
    );
  }
}
