import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/add_branch_controller.dart';

/// هيدر حوار الفرع.
class AddBranchHeader extends StatelessWidget {
  const AddBranchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final bool editing = context.read<AddBranchController>().isEditing;

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
            editing ? Icons.edit_outlined : Icons.add_business_outlined,
            size: 20,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            editing ? 'تعديل الفرع' : 'فرع جديد',
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
