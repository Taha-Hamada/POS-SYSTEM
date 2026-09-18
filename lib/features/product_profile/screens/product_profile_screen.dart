import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/product.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/not_found_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../products_list/data/products_repository.dart';
import '../controllers/product_profile_controller.dart';
import '../widgets/product_profile_tab_bar.dart';
import '../widgets/product_profile_tab_views.dart';
import '../widgets/product_summary_card.dart';

/// شاشة تفاصيل المنتج — بيانات قابلة للتعديل، أرصدة الفروع، وسجل الحركات.
class ProductProfileScreen extends StatefulWidget {
  const ProductProfileScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductProfileScreen> createState() => _ProductProfileScreenState();
}

class _ProductProfileScreenState extends State<ProductProfileScreen>
    with SingleTickerProviderStateMixin {
  /// الكنترولر محتاج vsync عشان الـTabController اللي جواه.
  late final ProductProfileController _profile;

  @override
  void initState() {
    super.initState();

    final ApiClient api = context.read<ApiClient>();

    _profile = ProductProfileController(
      ProductsRepository(api),
      InventoryRepository(api),
      productId: widget.productId,
      vsync: this,
    )..load();
  }

  @override
  void dispose() {
    _profile.dispose();
    super.dispose();
  }

  /// الشاشة بتتفتح فوق قايمة المنتجات، فالرجوع بيقفلها مش بيعيد بناء القايمة.
  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/products');
  }

  Future<void> _toggleActive() async {
    final Product? product = _profile.product;
    if (product == null) return;

    final bool activating = !product.isActive;
    final String? error = await _profile.toggleActive();
    if (!mounted) return;

    showAppSnackBar(
      context,
      error ??
          (activating
              ? 'رجع «${product.name}» للبيع'
              : 'اتوقف «${product.name}» ومبقاش بيظهر في البيع'),
      isError: error != null,
    );
  }

  /// الفورم الكامل فيه المتغيرات والصورة وطباعة الباركود — مش في التفاصيل.
  Future<void> _openFullForm() async {
    await context.push<bool>('/products/${widget.productId}/edit');
    if (!mounted) return;

    await _profile.load();
  }

  @override
  Widget build(BuildContext context) {
    final bool canEdit = context.read<SessionController>().can(
      'product:manage',
    );

    return ChangeNotifierProvider<ProductProfileController>.value(
      value: _profile,
      child: Consumer<ProductProfileController>(
        builder: (BuildContext context, ProductProfileController p, _) {
          if (p.isFirstLoad) {
            return const LoadingView(message: 'بنفتح تفاصيل المنتج…');
          }

          // 404 معناها المنتج مش موجود، وأي خطأ تاني بيتعرض كفشل قابل للإعادة.
          if (p.failure?.isNotFound ?? false) {
            return NotFoundState(
              icon: Icons.inventory_2_outlined,
              message: 'لم يتم العثور على المنتج',
              backLabel: 'رجوع للمنتجات',
              onBack: _back,
            );
          }

          if (p.hasFailed) {
            return Padding(
              padding: AppSpacing.page,
              child: ErrorView(message: p.errorMessage!, onRetry: p.retry),
            );
          }

          final Product product = p.product!;

          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'تفاصيل المنتج',
                  subtitle: 'بيانات المنتج وأرصدته وحركاته في مكان واحد',
                  leading: BackCircleButton(
                    onTap: _back,
                    tooltip: 'رجوع للمنتجات',
                  ),
                  actions: <Widget>[
                    if (canEdit) ...<Widget>[
                      SecondaryButton(
                        label: product.isActive ? 'إيقاف المنتج' : 'رجوعه للبيع',
                        icon: product.isActive
                            ? Icons.block_rounded
                            : Icons.restore_rounded,
                        tone: product.isActive
                            ? SecondaryButtonTone.danger
                            : SecondaryButtonTone.success,
                        onPressed: p.isLoading ? null : _toggleActive,
                      ),
                      PrimaryButton(
                        label: 'الفورم الكامل',
                        icon: Icons.tune_rounded,
                        onPressed: p.isLoading ? null : _openFullForm,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                ProductSummaryCard(
                  product: product,
                  onHand: p.totalOnHand,
                  branches: p.branchStock.length,
                ),
                const SizedBox(height: AppSpacing.xl),
                const ProductProfileTabBar(),
                const SizedBox(height: AppSpacing.lg),
                Expanded(child: ProductProfileTabViews(canEdit: canEdit)),
              ],
            ),
          );
        },
      ),
    );
  }
}
