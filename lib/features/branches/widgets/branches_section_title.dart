import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/branches_controller.dart';

/// عنوان قسم الشبكة مع عدّاد الفروع.
class BranchesSectionTitle extends StatelessWidget {
  const BranchesSectionTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final int count = context.select((BranchesController b) => b.rows.length);

    return Row(
      children: <Widget>[
        Text('كل الفروع', style: AppText.sectionTitle),
        const SizedBox(width: AppSpacing.md),
        Text('(${Fmt.count(count)})', style: AppText.caption),
      ],
    );
  }
}
