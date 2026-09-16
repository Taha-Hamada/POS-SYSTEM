import 'package:flutter/material.dart';

import '../../../core/models/promotion.dart';
import '../../../theme/app_theme.dart';

/// لون مميّز لكل نوع عرض.
extension PromotionTypeColor on PromotionType {
  Color get color => switch (this) {
    PromotionType.percentage => AppColors.accent,
    PromotionType.buyXGetY => const Color(0xFFEC4899),
    PromotionType.quantityDiscount => const Color(0xFF0EA5E9),
  };

  /// شرح قصير تحت اختيار النوع في الفورم.
  String get hint => switch (this) {
    PromotionType.percentage => 'خصم بنسبة ثابتة على الأصناف المشمولة',
    PromotionType.buyXGetY => 'كل مجموعة كاملة بتاخد قطع مجانية',
    PromotionType.quantityDiscount => 'الخصم بيشتغل لما كمية الصنف توصل للحد',
  };
}
