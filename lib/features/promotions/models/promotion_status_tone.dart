import 'package:flutter/material.dart';

import '../../../core/models/promotion.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';

/// نغمة الـBadge حسب حالة العرض.
extension PromotionStatusTone on PromotionStatus {
  StatusTone get tone => switch (this) {
    PromotionStatus.active => StatusTone.success,
    PromotionStatus.scheduled => StatusTone.info,
    PromotionStatus.expired => StatusTone.neutral,
    PromotionStatus.stopped => StatusTone.danger,
  };

  /// اللون المستخدم في شرائح الفلترة.
  Color get pillColor => switch (this) {
    PromotionStatus.active => AppColors.success,
    PromotionStatus.scheduled => AppColors.info,
    PromotionStatus.expired => AppColors.textSecondary,
    PromotionStatus.stopped => AppColors.danger,
  };
}
