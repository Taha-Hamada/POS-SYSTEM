import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// شارة المتبقي بعد الاستلام الحالي.
class ReceiveRemainingBadge extends StatelessWidget {
  const ReceiveRemainingBadge({super.key, required this.remaining});

  final double remaining;

  @override
  Widget build(BuildContext context) {
    final bool complete = remaining <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: complete ? AppColors.successSoft : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        complete ? 'مكتمل' : Fmt.count(remaining.round()),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: complete ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }
}
