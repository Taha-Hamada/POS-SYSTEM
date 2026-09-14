import 'package:flutter/material.dart';

import '../../../core/models/purchase_order.dart';
import '../../../core/widgets/hover_row_action.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../theme/app_theme.dart';

/// أزرار الصف حسب حالة الأمر: تأكيد للمسودة، استلام للمؤكد، وإلغاء لو متاح.
class PurchaseOrderRowAction extends StatelessWidget {
  const PurchaseOrderRowAction({
    super.key,
    required this.order,
    required this.hovered,
    required this.onPressed,
    required this.onCancel,
  });

  final PurchaseOrder order;
  final bool hovered;
  final VoidCallback onPressed;
  final VoidCallback onCancel;

  String get _label => switch (order.status) {
        PurchaseOrderStatus.draft => 'تأكيد',
        PurchaseOrderStatus.confirmed => 'استلام',
        PurchaseOrderStatus.partiallyReceived => 'استلام',
        _ => 'عرض',
      };

  Color get _color => switch (order.status) {
        PurchaseOrderStatus.draft => AppColors.info,
        PurchaseOrderStatus.confirmed => AppColors.success,
        PurchaseOrderStatus.partiallyReceived => AppColors.success,
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return HoverRowAction(
      hovered: hovered,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // الإلغاء بيختفي لما السيرفر يرفضه أصلًا: مكتمل، ملغي، أو دخل منه بضاعة.
          if (order.canCancel) ...<Widget>[
            PrimaryButton(
              label: 'إلغاء',
              size: AppButtonSize.small,
              color: AppColors.danger,
              onPressed: onCancel,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          PrimaryButton(
            label: _label,
            size: AppButtonSize.small,
            color: _color,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
