import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/promotion.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../../products_list/data/products_repository.dart';
import '../controllers/promotions_controller.dart';
import '../data/promotions_repository.dart';
import '../widgets/promotions_filter_bar.dart';
import '../widgets/promotions_grid.dart';
import 'create_promotion_dialog.dart';

/// شاشة العروض — بتجمّع شريط الفلترة وشبكة البطاقات بس.
class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  Future<void> _openForm(BuildContext context, {Promotion? existing}) async {
    final PromotionsController promotions = context
        .read<PromotionsController>();

    final bool? saved = await showCreatePromotionDialog(
      context,
      promotions: promotions,
      initial: existing,
    );

    if (saved != true || !context.mounted) return;

    showAppSnackBar(
      context,
      existing == null
          ? 'اتضاف العرض وهيتطبق تلقائي على الفواتير في مدته'
          : 'اتحفظت تعديلات العرض',
      width: 480,
    );
  }

  Future<void> _toggleActive(BuildContext context, Promotion promotion) async {
    final String? error = await context.read<PromotionsController>().setActive(
      promotion,
      isActive: !promotion.isActive,
    );
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      error ??
          (promotion.isActive
              ? 'اتوقف «${promotion.name}» ومبقاش بيتطبق'
              : 'اتفعّل «${promotion.name}»'),
      isError: error != null,
      width: 460,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ApiClient api = context.read<ApiClient>();
    final bool canManage = context.read<SessionController>().can(
      'promotion:manage',
    );

    return ChangeNotifierProvider<PromotionsController>(
      create: (_) => PromotionsController(
        PromotionsRepository(api),
        ProductsRepository(api),
        canManage: canManage,
      )..load(),
      child: Builder(
        builder: (BuildContext context) {
          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'العروض والخصومات',
                  subtitle:
                      'العروض بتتطبق تلقائي على فواتير الكاشير خلال مدتها',
                  actions: <Widget>[
                    if (canManage)
                      PrimaryButton(
                        label: 'إنشاء عرض جديد',
                        icon: Icons.add_rounded,
                        onPressed: () => _openForm(context),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const PromotionsFilterBar(),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: PromotionsGrid(
                    onEdit: canManage
                        ? (Promotion p) => _openForm(context, existing: p)
                        : null,
                    onToggleActive: canManage
                        ? (Promotion p) => _toggleActive(context, p)
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
