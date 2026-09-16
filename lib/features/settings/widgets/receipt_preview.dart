import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';

/// معاينة مبسّطة لشكل الإيصال ببيانات المتجر الحالية.
class ReceiptPreview extends StatelessWidget {
  const ReceiptPreview({
    super.key,
    required this.storeName,
    required this.footer,
    this.subtitle = '',
    this.widthMm = 80,
  });

  final String storeName;
  final String subtitle;
  final String footer;

  /// الورق الأضيق بيتعرض أضيق عشان المعاينة تقرّب من الحقيقة.
  final int widthMm;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widthMm <= 58 ? 200 : 260,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.storefront_rounded,
            size: 26,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            storeName.trim().isEmpty ? '—' : storeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.cardTitle.copyWith(fontSize: 14),
          ),
          if (subtitle.trim().isNotEmpty)
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(fontSize: 10.5),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1),
          ),
          // أسطر رمزية بتمثّل أصناف الفاتورة
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    width: 38,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1),
          ),
          Row(
            children: <Widget>[
              Text(
                'الإجمالي',
                style: AppText.bodyMedium.copyWith(fontSize: 12),
              ),
              const Spacer(),
              Text(
                Fmt.money(348.50),
                style: AppText.amountSm.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            footer.isEmpty ? '—' : footer,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
