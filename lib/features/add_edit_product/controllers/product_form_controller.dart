import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../products_list/data/products_repository.dart';
import '../models/product_form_tab.dart';
import '../models/product_variant.dart';

/// حالة نموذج المنتج كامل: كل الحقول + التبويب المفتوح.
class ProductFormController extends ChangeNotifier with LoadState {
  ProductFormController(
    this._repository, {
    required TickerProvider vsync,
    this.branchId,
  }) {
    tabController = TabController(
      length: ProductFormTab.values.length,
      vsync: vsync,
    )..addListener(() {
        if (tabController.indexIsChanging) notifyListeners();
      });
  }

  final ProductsRepository _repository;

  /// فرع الرصيد الافتتاحي — فرع المستخدم.
  final String? branchId;

  /// الوحدات المتاحة في تبويب المخزون
  static const List<String> units = <String>[
    'قطعة',
    'كيس',
    'علبة',
    'كرتونة',
    'زجاجة',
    'كيلو',
    'شريط',
  ];

  late final TabController tabController;

  // ── بيانات أساسية ────────────────────────────────────────────────────────
  final TextEditingController nameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<Category> _categories = <Category>[];
  String? _categoryId;

  // ── التسعير ──────────────────────────────────────────────────────────────
  final TextEditingController costController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  // ── المتغيرات ────────────────────────────────────────────────────────────
  final List<ProductVariant> _variants = <ProductVariant>[ProductVariant()];

  // ── المخزون ──────────────────────────────────────────────────────────────
  final TextEditingController reorderController =
      TextEditingController(text: '10');
  final TextEditingController openingStockController =
      TextEditingController(text: '0');
  String _unit = 'قطعة';

  // ── الباركود ─────────────────────────────────────────────────────────────
  String _barcode = '';

  List<Category> get categories => _categories;
  String? get categoryId => _categoryId;
  String get unit => _unit;
  String get barcode => _barcode;

  List<ProductVariant> get variants =>
      List<ProductVariant>.unmodifiable(_variants);

  int get currentTabIndex => tabController.index;

  /// الأقسام لازم تتحمّل قبل ما الفورم يقدر يحفظ.
  Future<void> load() async {
    await runLoad(() async {
      _categories = await _repository.fetchCategories();
      _categoryId ??= _categories.isEmpty ? null : _categories.first.id;
    });
  }

  Future<void> retry() => load();

  // ── حسابات التسعير ───────────────────────────────────────────────────────
  double get cost => double.tryParse(costController.text.trim()) ?? 0;
  double get price => double.tryParse(priceController.text.trim()) ?? 0;
  double get profit => price - cost;
  double get margin => price <= 0 ? 0 : (profit / price) * 100;
  bool get hasPricing => cost > 0 && price > 0;
  bool get isLoss => hasPricing && profit < 0;

  // ── حالة الحفظ ───────────────────────────────────────────────────────────
  String get productName => nameController.text.trim();
  String get sku => skuController.text.trim();

  bool get hasName => productName.isNotEmpty;
  bool get hasSku => sku.isNotEmpty;

  /// السيرفر بيرفض السعر الأقل من التكلفة، فبنمنعه من هنا.
  bool get canSave =>
      hasName && hasSku && _categoryId != null && !isLoss && !isLoading;

  /// نص التنبيه في تبويب المخزون
  String get reorderPoint => reorderController.text.trim().isEmpty
      ? '0'
      : reorderController.text.trim();

  // ── إجراءات ──────────────────────────────────────────────────────────────
  /// أي تغيير في حقل نصي بيعيد بناء الأجزاء اللي بتعتمد عليه.
  void fieldChanged([String? _]) => notifyListeners();

  void setCategory(String id) {
    _categoryId = id;
    notifyListeners();
  }

  void setUnit(String unit) {
    _unit = unit;
    notifyListeners();
  }

  void addVariant() {
    _variants.add(ProductVariant());
    notifyListeners();
  }

  void removeVariantAt(int index) {
    _variants.removeAt(index);
    notifyListeners();
  }

  void generateBarcode() {
    final int suffix =
        DateTime.now().millisecondsSinceEpoch.remainder(10000000);
    _barcode = '622103${suffix.toString().padLeft(7, '0')}';
    notifyListeners();
  }

  void goToTab(ProductFormTab tab) => tabController.animateTo(tab.index);

  /// بيحفظ المنتج على السيرفر. بيرجّع المنتج لو نجح، و`null` لو فشل.
  ///
  /// [saveError] بيحمل السبب عشان الشاشة تعرضه.
  String? saveError;

  Future<Product?> save() async {
    saveError = null;

    Product? created;

    final ApiException? failure = await runAction(() async {
      created = await _repository.create(
        name: productName,
        sku: sku,
        categoryId: _categoryId!,
        price: price,
        cost: cost,
        unit: _unit,
        brand: brandController.text.trim(),
        description: descriptionController.text.trim(),
        barcode: _barcode.isEmpty ? null : _barcode,
        minStock: int.tryParse(reorderController.text.trim()) ?? 0,
        openingStock: int.tryParse(openingStockController.text.trim()) ?? 0,
        branchId: branchId,
        // الصفوف الفاضية موجودة عشان المستخدم يكتب فيها، مش عشان تتبعت.
        variants: _variants
            .where((ProductVariant v) => !v.isEmpty)
            .map((ProductVariant v) => v.toInput())
            .toList(growable: false),
      );
    });

    if (failure != null) {
      // خطأ الحقل أدق من الرسالة العامة لما السيرفر يحدّده.
      saveError = failure.fieldErrors['sku'] ??
          failure.fieldErrors['barcode'] ??
          failure.fieldErrors['name'] ??
          failure.message;
      notifyListeners();
      return null;
    }

    return created;
  }

  @override
  void dispose() {
    tabController.dispose();
    nameController.dispose();
    skuController.dispose();
    brandController.dispose();
    descriptionController.dispose();
    costController.dispose();
    priceController.dispose();
    reorderController.dispose();
    openingStockController.dispose();
    super.dispose();
  }
}
