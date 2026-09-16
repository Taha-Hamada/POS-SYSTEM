import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// سطر إرشادي صغير تحت محتوى التبويب.
class FormHintRow extends StatelessWidget {
  const FormHintRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: AppText.caption.copyWith(fontSize: 11.5)),
        ),
      ],
    );
  }
}
