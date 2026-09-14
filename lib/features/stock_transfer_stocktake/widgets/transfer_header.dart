import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// هيدر حوار التحويل: العنوان وزرار الإغلاق وشريط المراحل.
class TransferHeader extends StatelessWidget {
  const TransferHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppRadius.xl),
          topLeft: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: AppRadius.mdAll,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  size: 20,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('تحويل مخزون', style: AppText.sectionTitle),
                    const SizedBox(height: 2),
                    Text(
                      'نقل أصناف من فرع إلى فرع آخر ومتابعة حالة الشحنة',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'إغلاق',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
