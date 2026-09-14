import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/customer.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/not_found_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/customer_profile_controller.dart';
import '../data/customers_repository.dart';
import '../widgets/customer_form_dialog.dart';
import '../widgets/customer_profile_tab_bar.dart';
import '../widgets/customer_profile_tab_views.dart';
import '../widgets/customer_summary_card.dart';

/// شاشة ملف العميل — بتجمّع الهيدر وبطاقة الملخّص والتبويبات بس.
class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key, required this.customerId});

  final String customerId;

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with SingleTickerProviderStateMixin {
  /// الكنترولر محتاج vsync عشان الـTabController اللي جواه.
  late final CustomerProfileController _profile;

  @override
  void initState() {
    super.initState();

    _profile = CustomerProfileController(
      CustomersRepository(context.read<ApiClient>()),
      customerId: widget.customerId,
      vsync: this,
    )..load();
  }

  @override
  void dispose() {
    _profile.dispose();
    super.dispose();
  }

  Future<void> _collect() async {
    final Customer? customer = _profile.customer;
    if (customer == null) return;

    if (!customer.hasDebt) {
      showAppSnackBar(context, 'العميل مش عليه مديونية');
      return;
    }

    final double? amount =
        await showCollectPaymentDialog(context, debt: customer.debt);
    if (amount == null || !mounted) return;

    final String? error = await _profile.recordPayment(amount: amount);
    if (!mounted) return;

    showAppSnackBar(
      context,
      error ?? 'اتحصّل ${Fmt.money(amount)} من ${customer.name}',
      isError: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CustomerProfileController>.value(
      value: _profile,
      child: Consumer<CustomerProfileController>(
        builder: (BuildContext context, CustomerProfileController p, _) {
          if (p.isFirstLoad) {
            return const LoadingView(message: 'بنفتح ملف العميل…');
          }

          // 404 معناها العميل مش موجود، وأي خطأ تاني بيتعرض كفشل قابل للإعادة.
          if (p.failure?.isNotFound ?? false) {
            return NotFoundState(
              icon: Icons.person_off_outlined,
              message: 'لم يتم العثور على العميل',
              onBack: () => context.go('/customers'),
            );
          }

          if (p.hasFailed) {
            return Padding(
              padding: AppSpacing.page,
              child: ErrorView(message: p.errorMessage!, onRetry: p.retry),
            );
          }

          final Customer customer = p.customer!;

          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'ملف العميل',
                  subtitle: 'كل تعاملات العميل في مكان واحد',
                  leading: BackCircleButton(
                    onTap: () => context.go('/customers'),
                    tooltip: 'رجوع للعملاء',
                  ),
                  actions: <Widget>[
                    SecondaryButton(
                      label: 'كشف حساب PDF',
                      icon: Icons.picture_as_pdf_outlined,
                      onPressed: () {},
                    ),
                    PrimaryButton(
                      label: 'تحصيل دفعة',
                      icon: Icons.payments_outlined,
                      onPressed: p.isLoading ? null : _collect,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomerSummaryCard(customer: customer),
                const SizedBox(height: AppSpacing.xl),
                const CustomerProfileTabBar(),
                const SizedBox(height: AppSpacing.lg),
                Expanded(child: CustomerProfileTabViews(customer: customer)),
              ],
            ),
          );
        },
      ),
    );
  }
}
