import 'package:flutter/material.dart';

import '../../../core/models/category.dart';
import '../../../core/models/material_icon_names.dart';
import '../../../theme/app_theme.dart';
import '../controllers/categories_controller.dart';
import '../data/categories_repository.dart';

/// بيبعت القسم للسيرفر ويرجّع رسالة الخطأ لو رفض.
typedef CategorySubmit = Future<String?> Function(CategoryInput input);

/// ألوان جاهزة للأقسام — كفاية للتمييز من غير منتقي ألوان كامل.
const List<Color> _palette = <Color>[
  Color(0xFF6366F1),
  Color(0xFF3B82F6),
  Color(0xFF0EA5E9),
  Color(0xFF10B981),
  Color(0xFF84CC16),
  Color(0xFFF59E0B),
  Color(0xFFF97316),
  Color(0xFFEF4444),
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFF64748B),
];

/// حوار إضافة أو تعديل قسم. بيرجّع true لو اتحفظ.
Future<bool?> showCategoryFormDialog(
  BuildContext context, {
  required List<Category> roots,
  required CategorySubmit onSubmit,
  Category? initial,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) =>
        _CategoryFormDialog(roots: roots, onSubmit: onSubmit, initial: initial),
  );
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({
    required this.roots,
    required this.onSubmit,
    this.initial,
  });

  final List<Category> roots;
  final CategorySubmit onSubmit;
  final Category? initial;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name,
  );
  late String _icon = widget.initial?.iconName ?? 'category';
  late Color _color = widget.initial?.color ?? _palette.first;
  late String? _parentId = widget.initial?.parentId;
  late bool _isActive = widget.initial?.isActive ?? true;

  bool _saving = false;
  String? _error;

  bool get _editing => widget.initial != null;

  /// القسم اللي تحته فروع مينفعش يبقى فرع — السيرفر بيسمح بمستوى واحد.
  List<Category> get _parentOptions => widget.roots
      .where((Category c) => c.id != widget.initial?.id)
      .toList(growable: false);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final String? failure = await widget.onSubmit(
      CategoryInput(
        name: _name.text.trim(),
        iconName: _icon,
        colorHex: CategoriesController.hexOf(_color),
        parentId: _parentId,
        isActive: _isActive,
      ),
    );

    if (!mounted) return;

    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _error = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool valid = _name.text.trim().length >= 2;

    return AlertDialog(
      title: Text(_editing ? 'تعديل القسم' : 'قسم جديد'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _name,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'اسم القسم'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String?>(
                initialValue:
                    _parentOptions.any((Category c) => c.id == _parentId)
                    ? _parentId
                    : null,
                decoration: const InputDecoration(labelText: 'تابع لقسم'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('قسم رئيسي'),
                  ),
                  for (final Category c in _parentOptions)
                    DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
                ],
                onChanged: (String? id) => setState(() => _parentId = id),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('الأيقونة', style: AppText.label),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final String name in availableIconNames)
                    InkWell(
                      borderRadius: AppRadius.smAll,
                      onTap: () => setState(() => _icon = name),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _icon == name
                              ? _color.withValues(alpha: 0.15)
                              : AppColors.surfaceAlt,
                          borderRadius: AppRadius.smAll,
                          border: Border.all(
                            color: _icon == name ? _color : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          iconForName(name),
                          size: 20,
                          color: _icon == name ? _color : AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('اللون', style: AppText.label),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: <Widget>[
                  for (final Color c in _palette)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.toARGB32() == _color.toARGB32()
                                ? AppColors.textPrimary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (_editing) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (bool v) => setState(() => _isActive = v),
                  title: const Text('القسم نشط'),
                  subtitle: const Text('القسم المعطّل مبيظهرش في شاشة البيع'),
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
          onPressed: valid && !_saving ? _submit : null,
          child: Text(_saving ? 'جاري الحفظ…' : 'حفظ'),
        ),
      ],
    );
  }
}
