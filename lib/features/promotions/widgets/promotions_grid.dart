import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/promotion.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../theme/app_theme.dart';
import '../controllers/promotions_controller.dart';
import 'promotion_card.dart';
import 'promotions_empty_state.dart';

/// شبكة بطاقات العروض.
class PromotionsGrid extends StatelessWidget {
  const PromotionsGrid({super.key, this.onEdit, this.onToggleActive});

  final ValueChanged<Promotion>? onEdit;
  final ValueChanged<Promotion>? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final PromotionsController promotions = context
        .watch<PromotionsController>();

    if (promotions.isFirstLoad) {
      return const LoadingView(message: 'بنحمّل العروض…');
    }

    if (promotions.hasFailed && promotions.rows.isEmpty) {
      return ErrorView(
        message: promotions.errorMessage!,
        onRetry: promotions.retry,
      );
    }

    final List<Promotion> rows = promotions.rows;
    if (rows.isEmpty) return const PromotionsEmptyState();

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 224,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
      ),
      itemCount: rows.length,
      itemBuilder: (BuildContext context, int i) => PromotionCard(
        key: ValueKey<String>(rows[i].id),
        promotion: rows[i],
        onEdit: onEdit == null ? null : () => onEdit!(rows[i]),
        onToggleActive: onToggleActive == null
            ? null
            : () => onToggleActive!(rows[i]),
      ),
    );
  }
}
