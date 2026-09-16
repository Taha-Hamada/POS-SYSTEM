import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import 'loyalty_tier_card_header.dart';

/// شارة مستوى العميل في جدول الترتيب.
class LoyaltyTierPill extends StatelessWidget {
  const LoyaltyTierPill({super.key, required this.tierKey, required this.name});

  /// regular = العميل لسه ماوصلش لأي مستوى
  final String tierKey;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (tierKey == 'regular') {
      return const StatusBadge(
        label: 'بدون مستوى',
        tone: StatusTone.neutral,
        showDot: false,
        compact: true,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md - 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: tierGradient(tierKey)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(tierIcon(tierKey), size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
