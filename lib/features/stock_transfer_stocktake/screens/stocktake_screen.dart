import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../theme/app_theme.dart';
import '../../inventory/data/inventory_repository.dart';
import '../controllers/stocktake_controller.dart';
import '../widgets/stocktake_footer.dart';
import '../widgets/stocktake_header.dart';
import '../widgets/stocktake_table.dart';
import '../widgets/stocktake_toolbar.dart';

/// شاشة جرد المخزون — بتجمّع الهيدر وشريط الأدوات والجدول والفوتر بس.
class StocktakeScreen extends StatelessWidget {
  const StocktakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الجرد بيتعمل على فرع. الحساب المش مربوط بفرع الكنترولر بيختار له
    // أول فرع، وبيبدّل بعدها من فلتر الفرع في شريط الأدوات.
    final String? branchId = context.read<SessionController>().user?.branchId;

    return ChangeNotifierProvider<StocktakeController>(
      create: (BuildContext context) => StocktakeController(
        InventoryRepository(context.read<ApiClient>()),
        branchId: branchId,
      )..load(),
      child: const _StocktakeBody(),
    );
  }
}

class _StocktakeBody extends StatelessWidget {
  const _StocktakeBody();

  @override
  Widget build(BuildContext context) {
    final StocktakeController stocktake = context.watch<StocktakeController>();

    if (stocktake.isFirstLoad) {
      return const LoadingView(message: 'بنجيب أرصدة الفرع…');
    }

    if (stocktake.hasFailed) {
      return Padding(
        padding: AppSpacing.page,
        child: ErrorView(
          message: stocktake.errorMessage!,
          onRetry: stocktake.retry,
        ),
      );
    }

    if (stocktake.hasNoBranches) {
      return const Padding(
        padding: AppSpacing.page,
        child: EmptyView(
          title: 'مفيش فروع متاحة',
          description: 'الجرد بيتعمل على فرع واحد. ضيف فرع من شاشة الفروع الأول.',
          icon: Icons.store_outlined,
        ),
      );
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const StocktakeHeader(),
                const SizedBox(height: AppSpacing.xl),
                const StocktakeToolbar(),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: stocktake.isEmpty
                      ? const EmptyView(
                          title: 'مفيش أصناف في الفرع ده',
                          icon: Icons.inventory_2_outlined,
                        )
                      : const StocktakeTable(),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        const StocktakeFooter(),
      ],
    );
  }
}
