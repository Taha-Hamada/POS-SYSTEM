import 'package:flutter/material.dart';

import '../../../core/models/loyalty_tier.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// ألوان وأيقونة كل مستوى — ثابتة في الواجهة لأن المستويات مفاتيحها ثابتة.
List<Color> tierGradient(String key) => switch (key) {
  'platinum' => const <Color>[Color(0xFF6366F1), Color(0xFF4C1D95)],
  'gold' => const <Color>[Color(0xFFF59E0B), Color(0xFFB45309)],
  _ => const <Color>[Color(0xFF94A3B8), Color(0xFF64748B)],
};

IconData tierIcon(String key) => switch (key) {
  'platinum' => Icons.diamond_outlined,
  'gold' => Icons.military_tech_outlined,
  _ => Icons.workspace_premium_outlined,
};

/// رأس بطاقة المستوى بتدرّج اللون المناسب ليه.
class LoyaltyTierCardHeader extends StatelessWidget {
  const LoyaltyTierCardHeader({
    super.key,
    required this.tier,
    required this.membersCount,
    this.onEdit,
  });

  final LoyaltyTier tier;
  final int membersCount;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final double pct = tier.discountPercent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: tierGradient(tier.key),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(tierIcon(tier.key), size: 23, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  tier.name,
                  style: AppText.pageTitle.copyWith(
                    fontSize: 21,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${Fmt.count(membersCount)} عميل',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'تعديل المستوى',
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'الحد الأدنى للتأهل — إجمالي المشتريات',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    Fmt.moneyRounded(tier.minPurchases),
                    style: AppText.amountHero.copyWith(
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'خصم ${pct == pct.roundToDouble() ? pct.toStringAsFixed(0) : pct.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
