import 'package:flutter/material.dart';

import '../models/product.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'status_badge.dart';

/// حوار بحث واختيار منتج — بيتستخدم في أوامر الشراء.
///
/// الكتالوج بيتبعت جاهز من الشاشة بدل ما الحوار يطلبه، عشان مايتحملش تاني مع
/// كل فتح والشاشة أصلًا محمّلاه.
Future<Product?> showProductPicker(
  BuildContext context, {
  required List<Product> catalog,
  Set<String> excludedIds = const <String>{},
}) {
  return showDialog<Product>(
    context: context,
    builder: (BuildContext context) =>
        _ProductPickerDialog(catalog: catalog, excludedIds: excludedIds),
  );
}

class _ProductPickerDialog extends StatefulWidget {
  const _ProductPickerDialog({
    required this.catalog,
    required this.excludedIds,
  });

  final List<Product> catalog;
  final Set<String> excludedIds;

  @override
  State<_ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<_ProductPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final String query = _query.trim().toLowerCase();

    final List<Product> results = widget.catalog.where((Product p) {
      if (widget.excludedIds.contains(p.id)) return false;
      if (query.isEmpty) return true;

      return p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          (p.barcode ?? '').contains(query);
    }).toList(growable: false);

    return Dialog(
      child: SizedBox(
        width: 560,
        height: 580,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: <Widget>[
                  Text('اختيار منتج', style: AppText.sectionTitle),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: TextField(
                autofocus: true,
                onChanged: (String v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'ابحث بالاسم أو الكود أو الباركود…',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد منتجات مطابقة',
                        style: AppText.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      itemCount: results.length,
                      itemBuilder: (BuildContext context, int i) {
                        final Product p = results[i];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.mdAll,
                          ),
                          hoverColor: AppColors.surfaceAlt,
                          onTap: () => Navigator.of(context).pop(p),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: p.accentColor.withValues(alpha: 0.12),
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Icon(
                              p.categoryIcon,
                              size: 19,
                              color: p.accentColor,
                            ),
                          ),
                          title: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyMedium.copyWith(fontSize: 13.5),
                          ),
                          subtitle: Text(
                            '${p.sku} • ${p.categoryName}',
                            style: AppText.caption.copyWith(fontSize: 11.5),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(
                                Fmt.money(p.price),
                                style: AppText.amountSm.copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 3),
                              StatusBadge.stock(
                                stock: p.stock,
                                minStock: p.minStock,
                                compact: true,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
