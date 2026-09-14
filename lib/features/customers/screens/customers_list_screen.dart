import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../controllers/customers_list_controller.dart';
import '../data/customers_repository.dart';
import '../widgets/customer_form_dialog.dart';
import '../widgets/customers_filter_bar.dart';
import '../widgets/customers_stat_cards.dart';
import '../widgets/customers_table.dart';

/// شاشة العملاء — بتجمّع الهيدر والبطاقات وشريط الفلترة والجدول بس.
class CustomersListScreen extends StatelessWidget {
  const CustomersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CustomersListController>(
      create: (BuildContext context) =>
          CustomersListController(CustomersRepository(context.read<ApiClient>()))
            ..load(),
      child: const _CustomersListBody(),
    );
  }
}

class _CustomersListBody extends StatelessWidget {
  const _CustomersListBody();

  Future<void> _addCustomer(BuildContext context) async {
    final CustomersListController customers =
        context.read<CustomersListController>();

    final NewCustomer? data = await showCustomerFormDialog(context);
    if (data == null || !context.mounted) return;

    final String? error = await customers.addCustomer(
      name: data.name,
      phone: data.phone,
      email: data.email,
      creditLimit: data.creditLimit,
    );

    if (!context.mounted) return;

    showAppSnackBar(
      context,
      error ?? 'اتضاف العميل ${data.name}',
      isError: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final CustomersListController customers =
        context.watch<CustomersListController>();

    return Padding(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ScreenHeader(
            title: 'العملاء',
            subtitle: 'إدارة قاعدة العملاء وأرصدتهم ونقاط الولاء',
            actions: <Widget>[
              PrimaryButton(
                label: 'إضافة عميل',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: () => _addCustomer(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(child: _content(customers)),
        ],
      ),
    );
  }

  Widget _content(CustomersListController customers) {
    if (customers.isFirstLoad) {
      return const LoadingView(message: 'بنجيب العملاء…');
    }

    if (customers.hasFailed) {
      return ErrorView(
        message: customers.errorMessage!,
        onRetry: customers.retry,
      );
    }

    if (customers.isEmpty) {
      return const EmptyView(
        title: 'مفيش عملاء لسه',
        description: 'ضيف أول عميل من زرار «إضافة عميل».',
        icon: Icons.people_outline_rounded,
      );
    }

    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CustomersStatCards(),
        SizedBox(height: AppSpacing.xl),
        CustomersFilterBar(),
        SizedBox(height: AppSpacing.lg),
        Expanded(child: CustomersTable()),
      ],
    );
  }
}
