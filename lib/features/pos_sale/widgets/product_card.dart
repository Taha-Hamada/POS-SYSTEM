import 'package:flutter/material.dart';

import '../../../core/models/product.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import 'product_card_thumbnail.dart';

/// بطاقة منتج في شبكة الكاشير — بتكبر شوية عند الـHover.
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Product p = widget.product;
    final bool disabled = p.isOutOfStock;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered && !disabled ? 1.025 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgAll,
              border: Border.all(
                color: _hovered && !disabled
                    ? AppColors.accent.withValues(alpha: 0.45)
                    : AppColors.border,
              ),
              boxShadow: _hovered && !disabled
                  ? AppShadows.lifted
                  : AppShadows.soft,
            ),
            child: Opacity(
              opacity: disabled ? 0.55 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: ProductCardThumbnail(
                      product: p,
                      showAddButton: _hovered && !disabled,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md - 2),
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle.copyWith(
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'المتاح: ${Fmt.count(p.stock)} ${p.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          Fmt.amount(p.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.amountMd.copyWith(fontSize: 16.5),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        Fmt.currencySymbol,
                        style: AppText.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
