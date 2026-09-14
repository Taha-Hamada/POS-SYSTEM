import 'package:flutter/material.dart';

import '../../../core/widgets/async_state_views.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../inventory/models/stock_record.dart';

/// بيختار صنف من أصناف الفرع المُرسِل.
///
/// بيعرض الرصيد المتاح جنب كل صنف عشان الموظف يعرف يحوّل كام قبل ما يختار،
/// والأصناف اللي رصيدها صفر مش بتظهر أصلًا.
Future<StockRecord?> showTransferProductPicker(
  BuildContext context, {
  required List<StockRecord> stock,
  required Set<String> excludedIds,
}) {
  return showDialog<StockRecord>(
    context: context,
    builder: (_) => _TransferProductPicker(
      stock: stock,
      excludedIds: excludedIds,
    ),
  );
}

class _TransferProductPicker extends StatefulWidget {
  const _TransferProductPicker({
    required this.stock,
    required this.excludedIds,
  });

  final List<StockRecord> stock;
  final Set<String> excludedIds;

  @override
  State<_TransferProductPicker> createState() => _TransferProductPickerState();
}

class _TransferProductPickerState extends State<_TransferProductPicker> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<StockRecord> get _results {
    final String q = _query.trim().toLowerCase();

    return widget.stock.where((StockRecord r) {
      if (widget.excludedIds.contains(r.productId)) return false;
      if (q.isEmpty) return true;

      return r.productName.toLowerCase().contains(q) ||
          r.sku.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<StockRecord> results = _results;

    return Dialog(
      child: SizedBox(
        width: 520,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Text('اختيار صنف', style: AppText.sectionTitle),
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
                controller: _search,
                autofocus: true,
                onChanged: (String v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'ابحث بالاسم أو الكود…',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: results.isEmpty
                  ? const EmptyView(
                      title: 'مفيش أصناف متاحة للتحويل',
                      description: 'كل الأصناف مضافة بالفعل أو رصيدها خلص.',
                      icon: Icons.inventory_2_outlined,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemBuilder: (BuildContext context, int i) => ListTile(
                        onTap: () => Navigator.of(context).pop(results[i]),
                        leading: Icon(
                          results[i].categoryIcon,
                          color: AppColors.accent,
                        ),
                        title: Text(
                          results[i].productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyMedium.copyWith(fontSize: 13.5),
                        ),
                        subtitle: Text(
                          results[i].sku,
                          style: AppText.caption.copyWith(fontSize: 11.5),
                        ),
                        trailing: Text(
                          'متاح ${Fmt.count(results[i].available)}',
                          style: AppText.caption.copyWith(fontSize: 12),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
