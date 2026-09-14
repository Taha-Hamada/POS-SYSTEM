import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../../suppliers/data/suppliers_repository.dart';
import '../controllers/purchase_orders_controller.dart';
import '../data/purchases_repository.dart';
import '../widgets/purchase_orders_filter_bar.dart';
import '../widgets/purchase_orders_stat_cards.dart';
import '../widgets/purchase_orders_table.dart';

/// شاشة أوامر الشراء — بتجمّع الهيدر والبطاقات وشريط الفلترة والجدول بس.
class PurchaseOrdersScreen extends StatelessWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiClient api = context.read<ApiClient>();

    return ChangeNotifierProvider<PurchaseOrdersController>(
      create: (_) => PurchaseOrdersController(
        PurchasesRepository(api),
        SuppliersRepository(api),
      )..load(),
      child: Builder(
        builder: (BuildContext context) {
          final bool canManage =
              context.read<SessionController>().can('purchase:manage');

          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'أوامر الشراء',
                  subtitle: 'متابعة طلبات التوريد من الموردين وحالة استلامها',
                  actions: <Widget>[
                    if (canManage)
                      PrimaryButton(
                        label: 'أمر شراء جديد',
                        icon: Icons.add_rounded,
                        onPressed: () => context.go('/purchases/new'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const PurchaseOrdersStatCards(),
                const SizedBox(height: AppSpacing.xl),
                const PurchaseOrdersFilterBar(),
                const SizedBox(height: AppSpacing.lg),
                const Expanded(child: PurchaseOrdersTable()),
              ],
            ),
          );
        },
      ),
    );
  }
}
