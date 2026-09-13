import 'package:flutter/material.dart';

import '../../../core/widgets/progress_track.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../models/dashboard_data.dart';

/// صف فرع في بطاقة أفضل الفروع.
class TopBranchRow extends StatelessWidget {
  const TopBranchRow({
    super.key,
    required this.performance,
    required this.rank,
    required this.maxSales,
  });

  final BranchStats performance;

  /// صفر = الأول (بياخد لون مميّز).
  final int rank;
  final double maxSales;

  @override
  Widget build(BuildContext context) {
    final bool isFirst = rank == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFirst
                  ? AppColors.warning.withValues(alpha: 0.14)
                  : AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${rank + 1}',
              style: AppText.amountSm.copyWith(
                fontSize: 13,
                color:
                    isFirst ? AppColors.warning : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        performance.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMedium.copyWith(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      Fmt.moneyRounded(performance.sales),
                      style: AppText.amountSm.copyWith(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ProgressTrack(
                        ratio: performance.sales / maxSales,
                        gradient: const LinearGradient(
                          colors: <Color>[
                            AppColors.accent,
                            Color(0xFF8B5CF6),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${performance.share.toStringAsFixed(1)}%',
                      style: AppText.caption.copyWith(
                        fontSize: 10.5,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
