import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/supplier.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../controllers/suppliers_list_controller.dart';
import '../data/suppliers_repository.dart';
import '../widgets/supplier_form_dialog.dart';
import '../widgets/suppliers_filter_bar.dart';
import '../widgets/suppliers_stat_cards.dart';
import '../widgets/suppliers_table.dart';

/// شاشة الموردين — بتجمّع الهيدر والبطاقات وشريط الفلترة والجدول بس.
class SuppliersListScreen extends StatelessWidget {
  const SuppliersListScreen({super.key});

  Future<void> _addSupplier(BuildContext context) async {
    final SuppliersListController suppliers =
        context.read<SuppliersListController>();

    final Supplier? created = await showSupplierFormDialog(context);
    if (created == null || !context.mounted) return;

    await suppliers.addCreated(created);
    if (!context.mounted) return;

    showPlainSnackBar(context, 'اتضاف المورد «${created.name}»');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SuppliersListController>(
      create: (BuildContext context) => SuppliersListController(
        SuppliersRepository(context.read<ApiClient>()),
      )..load(),
      child: Builder(
        builder: (BuildContext context) {
          final bool canManage =
              context.read<SessionController>().can('supplier:manage');

          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'الموردين',
                  subtitle: 'إدارة الموردين والمستحقات وأوامر التوريد',
                  actions: <Widget>[
                    if (canManage)
                      PrimaryButton(
                        label: 'إضافة مورد',
                        icon: Icons.add_business_outlined,
                        onPressed: () => _addSupplier(context),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const SuppliersStatCards(),
                const SizedBox(height: AppSpacing.xl),
                const SuppliersFilterBar(),
                const SizedBox(height: AppSpacing.lg),
                const Expanded(child: SuppliersTable()),
              ],
            ),
          );
        },
      ),
    );
  }
}
