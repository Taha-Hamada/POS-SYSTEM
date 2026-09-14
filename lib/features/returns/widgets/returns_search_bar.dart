import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/returns_controller.dart';
import 'returns_scanner_button.dart';

/// شريط البحث عن الفاتورة + زرار الماسح.
class ReturnsSearchBar extends StatelessWidget {
  const ReturnsSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ReturnsController returns = context.read<ReturnsController>();

    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 62,
            decoration: AppDecorations.card(radius: AppRadius.lg),
            child: TextField(
              controller: returns.searchController,
              focusNode: returns.searchFocus,
              autofocus: true,
              onSubmitted: returns.search,
              style: AppText.body.copyWith(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'ابحث برقم الفاتورة أو امسح الباركود',
                hintStyle: AppText.body.copyWith(
                  fontSize: 15.5,
                  color: AppColors.textMuted,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.md),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 24,
                    color: AppColors.textMuted,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 54),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: SecondaryButton(
                    label: 'بحث',
                    size: AppButtonSize.small,
                    onPressed: returns.search,
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 110),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ReturnsScannerButton(onTap: returns.search),
      ],
    );
  }
}
