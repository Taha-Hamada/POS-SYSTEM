import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../theme/app_theme.dart';
import '../controllers/products_list_controller.dart';
import '../data/products_repository.dart';
import '../widgets/products_filter_tabs.dart';
import '../widgets/products_list_header.dart';
import '../widgets/products_table.dart';

/// شاشة المنتجات — بتجمّع الهيدر والتبويبات والجدول بس.
class ProductsListScreen extends StatelessWidget {
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الأرصدة بتختلف من فرع للتاني، فبنطلب رصيد فرع المستخدم.
    final String? branchId = context.read<SessionController>().user?.branchId;

    return ChangeNotifierProvider<ProductsListController>(
      create: (BuildContext context) => ProductsListController(
        ProductsRepository(context.read<ApiClient>()),
        branchId: branchId,
      )..load(),
      child: const _ProductsListBody(),
    );
  }
}

class _ProductsListBody extends StatelessWidget {
  const _ProductsListBody();

  @override
  Widget build(BuildContext context) {
    final ProductsListController controller =
        context.watch<ProductsListController>();

    return Padding(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const ProductsListHeader(),
          const SizedBox(height: AppSpacing.xl),
          const ProductsFilterTabs(),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: _content(controller)),
        ],
      ),
    );
  }

  Widget _content(ProductsListController controller) {
    if (controller.isFirstLoad) {
      return const LoadingView(message: 'بنجيب المنتجات…');
    }

    if (controller.hasFailed) {
      return ErrorView(
        message: controller.errorMessage!,
        onRetry: controller.retry,
      );
    }

    if (controller.isEmpty) {
      return const EmptyView(
        title: 'مفيش منتجات لسه',
        description: 'ابدأ بإضافة أول منتج من زرار «منتج جديد».',
        icon: Icons.inventory_2_outlined,
      );
    }

    return const ProductsTable();
  }
}
