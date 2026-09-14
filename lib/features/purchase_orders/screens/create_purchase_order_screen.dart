import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/data/branches_repository.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../../products_list/data/products_repository.dart';
import '../../suppliers/data/suppliers_repository.dart';
import '../controllers/create_purchase_order_controller.dart';
import '../data/purchases_repository.dart';
import '../widgets/create_po_lines_card.dart';
import '../widgets/create_po_supplier_card.dart';
import '../widgets/create_po_totals_bar.dart';

/// شاشة أمر شراء جديد — بتجمّع الهيدر وبطاقة المورد وجدول الأصناف والإجماليات.
class CreatePurchaseOrderScreen extends StatelessWidget {
  const CreatePurchaseOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiClient api = context.read<ApiClient>();

    return ChangeNotifierProvider<CreatePurchaseOrderController>(
      create: (_) => CreatePurchaseOrderController(
        PurchasesRepository(api),
        SuppliersRepository(api),
        ProductsRepository(api),
        BranchesRepository(api),
        // البضاعة بتوصل فرع اللي عمل الأمر ما لم يختار غيره.
        branchId: context.read<SessionController>().user?.branchId,
      )..load(),
      child: const _CreatePurchaseOrderBody(),
    );
  }
}

class _CreatePurchaseOrderBody extends StatelessWidget {
  const _CreatePurchaseOrderBody();

  @override
  Widget build(BuildContext context) {
    final CreatePurchaseOrderController draft =
        context.watch<CreatePurchaseOrderController>();

    if (draft.isFirstLoad) {
      return const LoadingView(message: 'بنجهّز أمر الشراء…');
    }

    if (draft.hasFailed) {
      return ErrorView(message: draft.errorMessage!, onRetry: draft.retry);
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
                ScreenHeader(
                  title: 'أمر شراء جديد',
                  subtitle: 'اختر المورد وأضف الأصناف المطلوب توريدها',
                  leading: BackCircleButton(
                    onTap: () => context.go('/purchases'),
                    tooltip: 'رجوع لأوامر الشراء',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const CreatePoSupplierCard(),
                const SizedBox(height: AppSpacing.xl),
                const Expanded(child: CreatePoLinesCard()),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        const CreatePoTotalsBar(),
      ],
    );
  }
}
