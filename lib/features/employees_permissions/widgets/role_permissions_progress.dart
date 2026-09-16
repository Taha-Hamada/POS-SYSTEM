import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// شريط نسبة الصلاحيات المفعّلة أسفل كارت الدور.
class RolePermissionsProgress extends StatelessWidget {
  const RolePermissionsProgress({
    super.key,
    required this.enabledCount,
    required this.totalCount,
    required this.active,
  });

  final int enabledCount;
  final int totalCount;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final double ratio = totalCount == 0 ? 0 : enabledCount / totalCount;

    return Row(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: <Widget>[
                  Container(color: AppColors.border),
                  FractionallySizedBox(
                    widthFactor: ratio.clamp(0, 1),
                    child: Container(
                      color: active ? AppColors.accent : AppColors.borderStrong,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$enabledCount',
          style: AppText.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.accent : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
