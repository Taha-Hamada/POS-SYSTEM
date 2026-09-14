import 'package:flutter/material.dart';


import '../../../theme/app_theme.dart';

/// خلية الفرع: أيقونة (نجمة للفرع الرئيسي) + الاسم.
class StockBranchCell extends StatelessWidget {
  const StockBranchCell({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(
          Icons.store_outlined,
          size: 15,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
