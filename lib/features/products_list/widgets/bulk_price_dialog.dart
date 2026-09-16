import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../../core/utils/invoice_math.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/products_list_controller.dart';
import '../data/products_repository.dart';

enum _Target { visible, category }

/// حوار تعديل الأسعار الجماعي. بيرجّع عدد المنتجات اللي اتعدّلت.
Future<int?> showBulkPriceDialog(
  BuildContext context, {
  required ProductsListController products,
  required ProductsRepository repository,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) =>
        _BulkPriceDialog(products: products, repository: repository),
  );
}

class _BulkPriceDialog extends StatefulWidget {
  const _BulkPriceDialog({required this.products, required this.repository});

  final ProductsListController products;
  final ProductsRepository repository;

  @override
  State<_BulkPriceDialog> createState() => _BulkPriceDialogState();
}

class _BulkPriceDialogState extends State<_BulkPriceDialog> {
  /// السيرفر بيقبل 500 معرّف بس في الطلب الواحد.
  static const int _maxIds = 500;

  final TextEditingController _value = TextEditingController();

  late _Target _target = widget.products.categoryId != null
      ? _Target.category
      : _Target.visible;
  late String? _categoryId =
      widget.products.categoryId ??
      (widget.products.categories.isEmpty
          ? null
          : widget.products.categories.first.id);
  bool _percentage = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_value.text.trim());

  /// المنتجات اللي هيتعدّل سعرها من اللي محمّل على الشاشة.
  List<Product> get _affected => switch (_target) {
    _Target.visible => widget.products.rows.take(_maxIds).toList(),
    _Target.category =>
      widget.products.rows
          .where((Product p) => p.categoryId == _categoryId && p.isActive)
          .toList(),
  };

  /// نفس حسبة السيرفر عشان المعاينة تطابق النتيجة.
  double _newPrice(Product p) {
    final double value = _amount ?? 0;
    return _percentage
        ? round2(p.price * (1 + value / 100))
        : round2((p.price + value).clamp(0, double.infinity).toDouble());
  }

  String? get _problem {
    final double? value = _amount;
    if (value == null || value == 0) return 'اكتب قيمة التعديل';
    if (_percentage && value <= -100) return 'النسبة لازم تكون أكبر من ‎-100%';
    if (_target == _Target.category && _categoryId == null) {
      return 'اختار القسم';
    }
    if (_target == _Target.visible && widget.products.rows.isEmpty) {
      return 'مفيش منتجات معروضة';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final ({int matched, int modified}) result = await widget.repository
          .bulkUpdatePrices(
            productIds: _target == _Target.visible
                ? widget.products.rows
                      .take(_maxIds)
                      .map((Product p) => p.id)
                      .toList(growable: false)
                : null,
            categoryId: _target == _Target.category ? _categoryId : null,
            percentage: _percentage,
            value: _amount!,
          );

      if (!mounted) return;
      Navigator.of(context).pop(result.modified);
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = exception.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> affected = _affected;
    final int belowCost = _amount == null
        ? 0
        : affected.where((Product p) => _newPrice(p) < p.cost).length;
    final String? problem = _problem;

    return AlertDialog(
      title: const Text('تعديل الأسعار الجماعي'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('التعديل على', style: AppText.label),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<_Target>(
                segments: <ButtonSegment<_Target>>[
                  ButtonSegment<_Target>(
                    value: _Target.visible,
                    label: Text(
                      'المعروض (${Fmt.count(widget.products.rows.length)})',
                    ),
                    icon: const Icon(Icons.filter_list_rounded),
                  ),
                  const ButtonSegment<_Target>(
                    value: _Target.category,
                    label: Text('قسم كامل'),
                    icon: Icon(Icons.category_outlined),
                  ),
                ],
                selected: <_Target>{_target},
                onSelectionChanged: (Set<_Target> s) =>
                    setState(() => _target = s.first),
              ),
              if (_target == _Target.visible &&
                  widget.products.rows.length > _maxIds) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'هيتعدّل أول $_maxIds منتج بس — ضيّق البحث أو استخدم القسم.',
                  style: AppText.caption.copyWith(color: AppColors.warning),
                ),
              ],
              if (_target == _Target.category) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'القسم'),
                  items: <DropdownMenuItem<String>>[
                    for (final Category c in widget.products.categories)
                      DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                  ],
                  onChanged: (String? id) => setState(() => _categoryId = id),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'المنتجات النشطة بس في القسم هتتعدّل.',
                  style: AppText.caption,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SegmentedButton<bool>(
                    segments: const <ButtonSegment<bool>>[
                      ButtonSegment<bool>(value: true, label: Text('نسبة %')),
                      ButtonSegment<bool>(value: false, label: Text('مبلغ')),
                    ],
                    selected: <bool>{_percentage},
                    onSelectionChanged: (Set<bool> s) =>
                        setState(() => _percentage = s.first),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _value,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: _percentage ? 'النسبة' : 'المبلغ',
                        helperText: 'موجب للزيادة وسالب للتخفيض',
                        suffixText: _percentage ? '%' : 'ج.م',
                      ),
                    ),
                  ),
                ],
              ),
              if (_amount != null && affected.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text('معاينة', style: AppText.label),
                const SizedBox(height: AppSpacing.sm),
                for (final Product p in affected.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${Fmt.money(p.price)}  ←  ${Fmt.money(_newPrice(p))}',
                          style: AppText.amountSm,
                        ),
                      ],
                    ),
                  ),
                if (belowCost > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      '${Fmt.count(belowCost)} منتج هيبقى سعره أقل من تكلفته',
                      style: AppText.caption.copyWith(color: AppColors.danger),
                    ),
                  ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: problem == null && !_saving ? _submit : null,
          child: Text(_saving ? 'جاري التعديل…' : (problem ?? 'تطبيق التعديل')),
        ),
      ],
    );
  }
}
