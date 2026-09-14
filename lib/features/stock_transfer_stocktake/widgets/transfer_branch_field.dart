import 'package:flutter/material.dart';

import '../../../core/widgets/app_dropdown.dart';
import '../../../core/models/branch.dart';
import '../../../theme/app_theme.dart';

/// قائمة اختيار فرع (مُرسِل أو مُستقبِل) بعنوان ملوّن فوقها.
class TransferBranchField extends StatelessWidget {
  const TransferBranchField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onChanged,
    required this.branches,
  });

  final String label;
  final String value;

  /// الفروع اللي السيرفر رجّعها — مش قايمة ثابتة في الكود.
  final List<Branch> branches;
  final IconData icon;
  final Color color;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label, style: AppText.label.copyWith(fontSize: 12.5)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppDropdown<String>(
          value: value,
          width: double.infinity,
          height: 48,
          icon: Icons.store_outlined,
          onChanged: onChanged,
          items: <AppDropdownItem<String>>[
            for (final Branch b in branches)
              AppDropdownItem<String>(
                value: b.id,
                label: b.name,
                icon: Icons.store_outlined,
              ),
          ],
        ),
      ],
    );
  }
}
