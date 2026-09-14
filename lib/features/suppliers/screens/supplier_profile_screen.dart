import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/supplier.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/not_found_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../purchase_orders/data/purchases_repository.dart';
import '../controllers/supplier_profile_controller.dart';
import '../data/suppliers_repository.dart';
import '../widgets/supplier_form_dialog.dart';
import '../widgets/supplier_payment_dialog.dart';
import '../widgets/supplier_profile_tab_bar.dart';
import '../widgets/supplier_profile_tab_views.dart';
import '../widgets/supplier_summary_card.dart';

/// شاشة ملف المورد — بتجمّع الهيدر وبطاقة الملخّص والتبويبات بس.
class SupplierProfileScreen extends StatefulWidget {
  const SupplierProfileScreen({super.key, required this.supplierId});

  final String supplierId;

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen>
    with SingleTickerProviderStateMixin {
  late final SupplierProfileController _profile;

  @override
  void initState() {
    super.initState();

    final ApiClient api = context.read<ApiClient>();

    // الكنترولر محتاج vsync عشان الـTabController اللي جواه.
    _profile = SupplierProfileController(
      SuppliersRepository(api),
      PurchasesRepository(api),
      supplierId: widget.supplierId,
      vsync: this,
    )..load();
  }

  @override
  void dispose() {
    _profile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SupplierProfileController>.value(
      value: _profile,
      child: const _SupplierProfileBody(),
    );
  }
}

class _SupplierProfileBody extends StatelessWidget {
  const _SupplierProfileBody();

  Future<void> _pay(BuildContext context, Supplier supplier) async {
    final SupplierProfileController profile =
        context.read<SupplierProfileController>();

    final double? amount = await showSupplierPaymentDialog(context, supplier);
    if (amount == null || !context.mounted) return;

    final String? error = await profile.pay(amount: amount);
    if (!context.mounted) return;

    showPlainSnackBar(context, error ?? 'اتسجل السداد للمورد', width: 460);
  }

  Future<void> _edit(BuildContext context, Supplier supplier) async {
    final SupplierProfileController profile =
        context.read<SupplierProfileController>();

    final Supplier? saved =
        await showSupplierFormDialog(context, existing: supplier);
    if (saved == null || !context.mounted) return;

    await profile.load();
    if (!context.mounted) return;

    showPlainSnackBar(context, 'اتحدثت بيانات المورد');
  }

  @override
  Widget build(BuildContext context) {
    final SupplierProfileController profile =
        context.watch<SupplierProfileController>();

    if (profile.isFirstLoad) {
      return const LoadingView(message: 'بنجيب بيانات المورد…');
    }

    if (profile.notFound) {
      return NotFoundState(
        icon: Icons.local_shipping_outlined,
        message: 'لم يتم العثور على المورد',
        onBack: () => context.go('/suppliers'),
      );
    }

    final Supplier? supplier = profile.supplier;

    if (supplier == null) {
      return ErrorView(
        message: profile.errorMessage ?? 'مقدرناش نجيب بيانات المورد',
        onRetry: profile.retry,
      );
    }

    final bool canManage =
        context.read<SessionController>().can('supplier:manage');

    return Padding(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ScreenHeader(
            title: 'ملف المورد',
            subtitle: 'الأصناف والمستحقات وسجل التوريد',
            leading: BackCircleButton(
              onTap: () => context.go('/suppliers'),
              tooltip: 'رجوع للموردين',
            ),
            actions: <Widget>[
              if (canManage)
                SecondaryButton(
                  label: 'تعديل البيانات',
                  icon: Icons.edit_outlined,
                  onPressed: () => _edit(context, supplier),
                ),
              // السداد بيتقفل لما مفيش مستحق — السيرفر بيرفضه أصلًا.
              if (canManage && supplier.hasDue)
                PrimaryButton(
                  label: 'تسجيل دفعة',
                  icon: Icons.payments_outlined,
                  onPressed: () => _pay(context, supplier),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SupplierSummaryCard(supplier: supplier, profile: profile),
          const SizedBox(height: AppSpacing.xl),
          const SupplierProfileTabBar(),
          const SizedBox(height: AppSpacing.lg),
          const Expanded(child: SupplierProfileTabViews()),
        ],
      ),
    );
  }
}
