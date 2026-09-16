import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/promotion_form_controller.dart';

/// هيدر حوار العرض.
class CreatePromotionHeader extends StatelessWidget {
  const CreatePromotionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final bool editing = context.read<PromotionFormController>().isEditing;

    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: AppRadius.mdAll,
          ),
          child: Icon(
            editing ? Icons.edit_outlined : Icons.local_offer_outlined,
            size: 20,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            editing ? 'تعديل العرض' : 'عرض جديد',
            style: AppText.sectionTitle,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, size: 20),
        ),
      ],
    );
  }
}
