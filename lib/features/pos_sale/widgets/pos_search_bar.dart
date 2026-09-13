import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import 'pos_scanner_button.dart';
import 'pos_shortcut_hint.dart';

/// شريط البحث الكبير أعلى شاشة الكاشير + زر السكانر.
class PosSearchBar extends StatelessWidget {
  const PosSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onScan,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onScan;

  /// قارئ الباركود بيكتب الكود وبيبعت Enter، فده مدخل المسح الحقيقي.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 58,
            decoration: AppDecorations.card(radius: AppRadius.lg),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: AppText.body.copyWith(fontSize: 15.5),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو الكود أو امسح الباركود…',
                hintStyle: AppText.body.copyWith(
                  fontSize: 15,
                  color: AppColors.textMuted,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.md),
                  child: Icon(
                    Icons.search_rounded,
                    size: 24,
                    color: AppColors.textMuted,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 52),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (query.isNotEmpty)
                        IconButton(
                          tooltip: 'مسح',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: onClear,
                        ),
                      const PosShortcutHint(label: 'F2'),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        PosScannerButton(onTap: onScan),
      ],
    );
  }
}
