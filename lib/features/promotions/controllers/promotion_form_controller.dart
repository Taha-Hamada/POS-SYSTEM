import 'package:flutter/material.dart';

import '../../../core/models/promotion.dart';
import '../models/promotion_input.dart';

/// بيبعت العرض للسيرفر ويرجّع رسالة الخطأ لو رفض.
typedef PromotionSubmit = Future<String?> Function(PromotionInput input);

/// حالة نموذج العرض — إنشاء عرض جديد أو تعديل عرض موجود.
class PromotionFormController extends ChangeNotifier {
  PromotionFormController({Promotion? initial}) : isEditing = initial != null {
    final DateTime today = DateTime.now();
    _start = DateTime(today.year, today.month, today.day);
    _end = _start.add(const Duration(days: 30));

    if (initial == null) return;

    nameController.text = initial.name;
    percentController.text = _number(initial.discountPercent);
    minQuantityController.text = '${initial.minQuantity}';
    buyController.text = '${initial.buyQuantity}';
    getController.text = '${initial.getQuantity}';
    _type = initial.type;
    _scope = initial.scope;
    _categoryId = initial.categoryId;
    _productIds = initial.productIds.toSet();
    _start = DateTime(
      initial.startsAt.year,
      initial.startsAt.month,
      initial.startsAt.day,
    );
    _end = DateTime(
      initial.endsAt.year,
      initial.endsAt.month,
      initial.endsAt.day,
    );
  }

  final bool isEditing;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController percentController = TextEditingController();
  final TextEditingController minQuantityController = TextEditingController(
    text: '2',
  );
  final TextEditingController buyController = TextEditingController(text: '2');
  final TextEditingController getController = TextEditingController(text: '1');

  PromotionType _type = PromotionType.percentage;
  PromotionScope _scope = PromotionScope.all;
  String? _categoryId;
  Set<String> _productIds = <String>{};
  late DateTime _start;
  late DateTime _end;

  bool _saving = false;
  String? _error;
  String _productQuery = '';

  PromotionType get type => _type;
  PromotionScope get scope => _scope;
  String? get categoryId => _categoryId;
  Set<String> get productIds => _productIds;
  DateTime get start => _start;
  DateTime get end => _end;
  bool get saving => _saving;
  String? get error => _error;
  String get productQuery => _productQuery;

  /// الأيام شاملة يوم البداية والنهاية.
  int get durationDays => _end.difference(_start).inDays + 1;

  double get _percent => double.tryParse(percentController.text.trim()) ?? 0;
  int get _minQuantity => int.tryParse(minQuantityController.text.trim()) ?? 0;
  int get _buy => int.tryParse(buyController.text.trim()) ?? 0;
  int get _get => int.tryParse(getController.text.trim()) ?? 0;

  /// نفس شروط السيرفر، عشان الزرار مايتفعّلش على عرض هيترفض.
  String? get problem {
    if (nameController.text.trim().length < 2) return 'اكتب اسم العرض';
    if (_end.isBefore(_start)) return 'تاريخ النهاية قبل البداية';

    switch (_type) {
      case PromotionType.percentage:
        if (_percent <= 0 || _percent > 100) return 'نسبة الخصم بين 1 و 100';
      case PromotionType.quantityDiscount:
        if (_percent <= 0 || _percent > 100) return 'نسبة الخصم بين 1 و 100';
        if (_minQuantity < 2) return 'أقل كمية قطعتين على الأقل';
      case PromotionType.buyXGetY:
        if (_buy < 1 || _get < 1) return 'حدد عدد القطع المشتراة والمجانية';
    }

    if (_scope == PromotionScope.category && _categoryId == null) {
      return 'اختار القسم';
    }
    if (_scope == PromotionScope.products && _productIds.isEmpty) {
      return 'اختار منتج واحد على الأقل';
    }

    return null;
  }

  bool get isValid => problem == null;

  void fieldChanged([String? _]) => notifyListeners();

  void setType(PromotionType type) {
    _type = type;
    notifyListeners();
  }

  void setScope(PromotionScope scope) {
    _scope = scope;
    notifyListeners();
  }

  void setCategory(String? id) {
    _categoryId = id;
    notifyListeners();
  }

  void toggleProduct(String id) {
    _productIds = Set<String>.of(_productIds);
    if (!_productIds.remove(id)) _productIds.add(id);
    notifyListeners();
  }

  void setProductQuery(String value) {
    _productQuery = value;
    notifyListeners();
  }

  void setStart(DateTime date) {
    _start = date;
    // النهاية لازم تفضل بعد البداية
    if (_end.isBefore(_start)) _end = _start.add(const Duration(days: 30));
    notifyListeners();
  }

  void setEnd(DateTime date) {
    _end = date;
    notifyListeners();
  }

  /// العرض بيبدأ أول اليوم وبيخلص آخر ثانية في يوم النهاية.
  PromotionInput build() => PromotionInput(
    name: nameController.text.trim(),
    type: _type,
    discountPercent: _type == PromotionType.buyXGetY ? 0 : _percent,
    minQuantity: _type == PromotionType.quantityDiscount ? _minQuantity : 1,
    buyQuantity: _type == PromotionType.buyXGetY ? _buy : 1,
    getQuantity: _type == PromotionType.buyXGetY ? _get : 1,
    scope: _scope,
    categoryId: _categoryId,
    productIds: _productIds.toList(growable: false),
    startsAt: DateTime(_start.year, _start.month, _start.day),
    endsAt: DateTime(_end.year, _end.month, _end.day, 23, 59, 59),
  );

  Future<bool> submit(PromotionSubmit onSubmit) async {
    _saving = true;
    _error = null;
    notifyListeners();

    final String? failure = await onSubmit(build());

    _saving = false;
    _error = failure;
    notifyListeners();

    return failure == null;
  }

  static String _number(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  @override
  void dispose() {
    nameController.dispose();
    percentController.dispose();
    minQuantityController.dispose();
    buyController.dispose();
    getController.dispose();
    super.dispose();
  }
}
